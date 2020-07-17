require 'spec_helper'

describe "gws_monitor_topics", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let!(:u1) { create(:gws_user, group_ids: [g1.id], gws_role_ids: user.gws_role_ids) }
  let!(:u2) { create(:gws_user, group_ids: [g1.id], gws_role_ids: user.gws_role_ids) }
  let!(:u3) { create(:gws_user, group_ids: [g1.id], gws_role_ids: user.gws_role_ids) }
  let!(:topic) do
    create(
      :gws_monitor_topic, cur_site: site, cur_user: user, attend_group_ids: [g1.id], state: 'public',
      spec_config: 'my_group', permit_comment: "allow", answer_state_hash: { g1.id.to_s => "public" }
    )
  end
  let(:post_type) { %w(answer not_applicable).sample }
  let(:texts) do
    if post_type == "answer"
      Array.new(2) { "text-#{unique_id}" }
    else
      [ I18n.t("gws/monitor.options.answer_state.question_not_applicable") ]
    end
  end
  let!(:post) do
    create(
      :gws_monitor_post, cur_site: site, cur_user: u1, topic_id: topic.id, parent_id: topic.id, post_type: post_type,
      name: g1.section_name, text: texts.join("\n"), group_ids: [ g1.id ], state: "draft"
    )
  end

  describe "approval and circulation" do
    let(:application_comments) { Array.new(2) { "comment-#{unique_id}" } }
    let(:approval_comments) { Array.new(2) { "comment-#{unique_id}" } }
    let(:circulation_comments) { Array.new(2) { "comment-#{unique_id}" } }

    it do
      #
      # Send application
      #
      login_user u1
      visit gws_monitor_main_path(site: site)
      click_on topic.name
      within "#post-#{post.id}" do
        click_on I18n.t('gws/monitor.links.approval_application')
      end
      within "#addon-gws-agents-addons-monitor-approver" do
        click_on I18n.t("workflow.buttons.select")
      end
      within "#addon-gws-agents-addons-monitor-approver" do
        fill_in "workflow[comment]", with: application_comments.join("\n")

        click_on I18n.t("workflow.search_approvers.index")
      end
      wait_for_cbox do
        click_on u2.name
      end
      within "#addon-gws-agents-addons-monitor-approver" do
        click_on I18n.t("workflow.search_circulations.index")
      end
      wait_for_cbox do
        click_on u3.name
      end
      within "#addon-gws-agents-addons-monitor-approver" do
        expect(page).to have_content(u3.name)

        click_on I18n.t("workflow.buttons.request")
      end
      within "#addon-gws-agents-addons-monitor-approver" do
        within ".mod-workflow-view" do
          expect(page).to have_content(u1.name)
          expect(page).to have_content(u2.name)
        end
      end
      wait_for_notice(I18n.t("workflow.notice.request_sent"))

      expect(SS::Notification.all.count).to eq 1
      SS::Notification.all.reorder(created: -1).first.tap do |notice|
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ u2.id ]
        expect(notice.user_id).to eq u1.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/monitor/post/workflow_request.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/monitor/-/topics/#{topic.id}/comments/#{post.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank
      end

      #
      # Approve application
      #
      login_user u2
      visit gws_monitor_topics_path(site: site)
      click_on topic.name
      within "#post-#{post.id}" do
        click_on I18n.t('gws/monitor.links.approve')
      end
      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: approval_comments.join("\n")
        click_on I18n.t("workflow.buttons.approve")
      end
      wait_for_notice(I18n.t("workflow.notice.request_approved"))

      post.reload
      expect(post.state).to eq "approve"
      expect(post.public?).to be_truthy

      topic.reload
      expect(topic.answer_state_hash[g1.id.to_s]).to eq post_type == "answer" ? "answered" : "question_not_applicable"

      expect(SS::Notification.all.count).to eq 3
      SS::Notification.all.reorder(created: -1).second.tap do |notice|
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ u1.id ]
        expect(notice.user_id).to eq u2.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/monitor/post/workflow_approve.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/monitor/-/topics/#{topic.id}/comments/#{post.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank
      end
      SS::Notification.all.reorder(created: -1).first.tap do |notice|
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ u3.id ]
        expect(notice.user_id).to eq u2.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/monitor/post/workflow_circular.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/monitor/-/topics/#{topic.id}/comments/#{post.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank
      end

      #
      # Circular application
      #
      login_user u3
      visit gws_monitor_topics_path(site: site)
      within ".list-head-search" do
        select I18n.t("gws/monitor.options.answer_state_filter.answered"), from: "s[answer_state_filter]"
      end
      click_on topic.name
      within "#post-#{post.id}" do
        click_on I18n.t('ss.links.show')
      end
      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: circulation_comments.join("\n")
        click_on I18n.t("workflow.links.set_seen")
      end
      wait_for_notice(I18n.t("workflow.notice.set_seen"))

      expect(SS::Notification.all.count).to eq 4
      SS::Notification.all.reorder(created: -1).first.tap do |notice|
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ u1.id ]
        expect(notice.user_id).to eq u3.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/monitor/post/workflow_comment.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/monitor/-/topics/#{topic.id}/comments/#{post.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank
      end
    end
  end
end
