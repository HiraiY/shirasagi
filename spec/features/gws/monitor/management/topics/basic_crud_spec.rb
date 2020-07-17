require 'spec_helper'

describe "gws_monitor_management_topics", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}", order: 10) }
  let!(:g2) { create(:gws_group, name: "#{site.name}/g-#{unique_id}", order: 20) }
  let!(:u1) { create(:gws_user, group_ids: [g1.id], gws_role_ids: user.gws_role_ids) }
  let!(:u2) { create(:gws_user, group_ids: [g2.id], gws_role_ids: user.gws_role_ids) }
  let!(:file1) { tmp_ss_file(user: user, basename: "file1.png", contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
  let!(:file2) { tmp_ss_file(user: user, basename: "file2.png", contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }

  context "basic crud" do
    let(:name) { "name-#{unique_id}" }
    let(:spec_config) { %w(my_group other_groups other_groups_and_contents).sample }
    let(:notice_state) do
      %w(from_now 1_day_from_released 2_days_from_released 1_day_before_due_date 4_days_before_due_date).sample
    end
    let(:mode) { %w(thread tree).sample }
    let(:attend_group) { [ g1, g2 ].sample }
    let(:attend_user) { attend_group.id == g1.id ? u1 : u2 }
    let(:texts) { Array.new(2) { "text-#{unique_id}" } }
    let(:name2) { "name-#{unique_id}" }
    let(:texts2) { Array.new(2) { "text-#{unique_id}" } }

    before { login_gws_user }

    it do
      #
      # Create
      #
      visit gws_monitor_main_path(site: site)
      click_on I18n.t('gws/monitor.tabs.management_topic')
      click_on I18n.t("ss.links.new")

      within "form" do
        fill_in "item[name]", with: name
        select I18n.t("gws/monitor.options.spec_config.#{spec_config}"), from: "item[spec_config]"
        select I18n.t("gws/monitor.options.notice_state.#{notice_state}"), from: "item[notice_state]"
        select I18n.t("gws/monitor.options.mode.#{mode}"), from: "item[mode]"

        within "#addon-gws-agents-addons-monitor-group" do
          click_on I18n.t("ss.apis.groups.index")
        end
      end
      wait_for_cbox do
        click_on attend_group.trailing_name
      end
      within "form" do
        fill_in "item[text]", with: texts.join("\n")

        click_on I18n.t("ss.buttons.upload")
      end
      wait_for_cbox do
        click_on file1.name
      end
      within "form" do
        expect(page).to have_content(file1.name)
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice(I18n.t("ss.notice.saved"))

      expect(Gws::Monitor::Topic.topic.count).to eq 1
      topic = Gws::Monitor::Topic.topic.first
      expect(topic.name).to eq name
      expect(topic.spec_config).to eq spec_config
      expect(topic.notice_state).to eq notice_state
      expect(topic.mode).to eq mode
      expect(topic.attend_groups.count).to eq 1
      expect(topic.attend_groups.pluck(:id)).to include(attend_group.id)
      expect(topic.text).to eq texts.join("\r\n")
      expect(topic.files.count).to eq 1
      expect(topic.files.first.id).to eq file1.id
      expect(topic.state).to eq "draft"
      expect(topic.released).to be_blank
      expect(topic.groups.count).to eq 1
      expect(topic.groups.pluck(:id)).to include(*gws_user.group_ids)
      expect(topic.users.count).to eq 1
      expect(topic.users.pluck(:id)).to include(gws_user.id)
      expect(topic.deleted).to be_blank

      file1.reload
      expect(file1.owner_item_id).to eq topic.id

      #
      # Update
      #
      visit gws_monitor_management_main_path(site: site, category: '-')
      click_on topic.name
      click_on I18n.t("ss.links.edit")

      within "form" do
        fill_in "item[name]", with: name2
        fill_in "item[text]", with: texts2.join("\n")

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice(I18n.t("ss.notice.saved"))

      topic.reload
      expect(topic.name).to eq name2
      expect(topic.text).to eq texts2.join("\r\n")

      #
      # Publish
      #
      visit gws_monitor_management_topics_path(site: site, category: '-')
      click_on topic.name
      click_on I18n.t("gws/monitor.links.publish")
      within "form" do
        click_on I18n.t("gws/monitor.buttons.publish")
      end
      wait_for_notice(I18n.t("gws/monitor.notice.published"))

      topic.reload
      expect(topic.state).to eq "public"
      expect(topic.released).to be_present

      expect(SS::Notification.all.count).to eq 1
      SS::Notification.all.first.tap do |notice|
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ attend_user.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/monitor/topic.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/monitor/-/topics/#{topic.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank
      end

      #
      # Close
      #
      visit gws_monitor_management_topics_path(site: site, category: '-')
      click_on topic.name
      page.accept_confirm do
        click_on I18n.t("gws/monitor.links.closed")
      end
      wait_for_notice(I18n.t("gws/monitor.notice.close"))

      topic.reload
      expect(topic.state).to eq "closed"
      expect(topic.released).to be_present

      # 締め切っても通知は送られない
      expect(SS::Notification.all.count).to eq 1

      #
      # Open
      #
      visit gws_monitor_management_topics_path(site: site, category: '-')
      click_on topic.name
      click_on I18n.t("gws/monitor.links.open")
      within "form" do
        click_on I18n.t("gws/monitor.buttons.publish")
      end
      wait_for_notice(I18n.t("gws/monitor.notice.published"))

      topic.reload
      expect(topic.state).to eq "public"
      expect(topic.released).to be_present

      # 再配信すると通知が送られる
      expect(SS::Notification.all.count).to eq 2

      #
      # Close
      #
      visit gws_monitor_management_topics_path(site: site, category: '-')
      click_on topic.name
      page.accept_confirm do
        click_on I18n.t("gws/monitor.links.closed")
      end
      wait_for_notice(I18n.t("gws/monitor.notice.close"))

      topic.reload
      expect(topic.state).to eq "closed"
      expect(topic.released).to be_present

      #
      # Delete
      #
      visit gws_monitor_management_topics_path(site: site, category: '-')
      click_on topic.name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice(I18n.t("ss.notice.deleted"))

      topic.reload
      expect(topic.deleted).to be_present
    end
  end
end
