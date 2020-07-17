require 'spec_helper'

describe "gws_monitor_topics", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let!(:u1) { create(:gws_user, group_ids: [g1.id], gws_role_ids: user.gws_role_ids) }
  let!(:file1) { tmp_ss_file(user: u1, basename: "file1.png", contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
  let!(:topic) do
    create(
      :gws_monitor_topic, attend_group_ids: [g1.id], state: 'public', spec_config: 'my_group'
    )
  end

  describe "basic crud" do
    let(:texts) { Array.new(2) { "text-#{unique_id}" } }
    let(:texts2) { Array.new(2) { "text-#{unique_id}" } }

    before { login_user u1 }

    it do
      #
      # Confirm question
      #
      visit gws_monitor_main_path(site: site)
      click_on topic.name
      page.accept_confirm do
        click_on I18n.t('gws/monitor.links.public')
      end
      wait_for_notice(I18n.t("ss.notice.saved"))

      topic.reload
      expect(topic.answer_state_hash[g1.id.to_s]).to eq "public"

      #
      # Create answer as draft
      #
      click_on I18n.t('gws/monitor.links.draft_comment')
      within "form" do
        fill_in "item[text]", with: texts.join("\n")

        click_on I18n.t("ss.buttons.upload")
      end
      wait_for_cbox do
        click_on file1.name
      end
      within "form" do
        expect(page).to have_content(file1.name)
        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice(I18n.t("ss.notice.saved"))

      topic.reload
      expect(topic.descendants.count).to eq 1
      expect(topic.children.count).to eq 1
      expect(topic.answer_state_hash[g1.id.to_s]).to eq "public"

      post = topic.descendants.first
      expect(post.topic_id).to eq topic.id
      expect(post.parent_id).to eq topic.id
      expect(post.post_type).to eq "answer"
      expect(post.name).to eq g1.section_name
      expect(post.text).to eq texts.join("\r\n")
      expect(post.files.pluck(:id)).to eq [ file1.id ]
      expect(post.state).to eq "draft"
      expect(post.closed?).to be_truthy
      expect(post.released).to be_blank
      expect(post.group_ids).to eq [ g1.id ]

      #
      # Update answer
      #
      within "#post-#{post.id}" do
        click_on I18n.t('ss.links.edit')
      end
      within "form" do
        fill_in "item[text]", with: texts2.join("\n")
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice(I18n.t("ss.notice.saved"))

      #
      # Publish answer
      #
      within "#post-#{post.id}" do
        click_on I18n.t('gws/monitor.links.publish')
      end
      within "form" do
        page.accept_confirm do
          click_on I18n.t("gws/monitor.buttons.publish")
        end
      end
      wait_for_notice(I18n.t("ss.notice.saved"))

      post.reload
      expect(post.state).to eq "public"
      expect(post.public?).to be_truthy

      topic.reload
      expect(topic.answer_state_hash[g1.id.to_s]).to eq "answered"

      #
      # Depublish answer
      #
      within "#post-#{post.id}" do
        click_on I18n.t('gws/monitor.links.depublish')
      end
      within "form" do
        click_on I18n.t("gws/monitor.buttons.depublish")
      end
      wait_for_notice(I18n.t("ss.notice.saved"))

      post.reload
      expect(post.state).to eq "draft"
      expect(post.closed?).to be_truthy

      topic.reload
      expect(topic.answer_state_hash[g1.id.to_s]).to eq "public"

      #
      # Delete answer
      #
      within "#post-#{post.id}" do
        click_on I18n.t('ss.links.delete')
      end
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice(I18n.t("ss.notice.deleted"))

      expect { post.reload }.to raise_error Mongoid::Errors::DocumentNotFound

      topic.reload
      expect(topic.descendants.count).to eq 0
      expect(topic.children.count).to eq 0
      expect(topic.answer_state_hash[g1.id.to_s]).to eq "public"
    end
  end
end
