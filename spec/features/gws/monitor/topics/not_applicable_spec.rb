require 'spec_helper'

describe "gws_monitor_topics", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let!(:u1) { create(:gws_user, group_ids: [g1.id], gws_role_ids: user.gws_role_ids) }
  let!(:topic) do
    create(
      :gws_monitor_topic, attend_group_ids: [g1.id], state: 'public', spec_config: 'my_group'
    )
  end

  describe "question is not applicable" do
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
      click_on I18n.t('gws/monitor.links.question_not_applicable')
      within "form" do
        click_on I18n.t("gws/monitor.links.question_not_applicable_draft")
      end
      wait_for_notice(I18n.t("ss.notice.saved"))

      topic.reload
      expect(topic.descendants.count).to eq 1
      expect(topic.children.count).to eq 1
      expect(topic.answer_state_hash[g1.id.to_s]).to eq "public"

      post = topic.descendants.first
      expect(post.topic_id).to eq topic.id
      expect(post.parent_id).to eq topic.id
      expect(post.post_type).to eq "not_applicable"
      expect(post.name).to eq g1.section_name
      expect(post.text).to eq I18n.t("gws/monitor.options.answer_state.question_not_applicable")
      expect(post.files.count).to eq 0
      expect(post.state).to eq "draft"
      expect(post.closed?).to be_truthy
      expect(post.released).to be_blank
      expect(post.group_ids).to eq [ g1.id ]

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
      expect(topic.answer_state_hash[g1.id.to_s]).to eq "question_not_applicable"

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
