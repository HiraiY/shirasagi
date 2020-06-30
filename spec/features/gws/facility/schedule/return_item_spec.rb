require 'spec_helper'

describe "gws_facility_schedule", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  let(:start_at) { Time.zone.now.change(min: 0, sec: 0) }
  let(:end_at) { start_at.advance(hours: 1) }

  let(:facility) { create :gws_facility_item, approval_check_state: "enabled", loan_state: "enabled", user_ids: [user.id] }
  let!(:item1) do
    create(
      :gws_schedule_facility_plan,
      start_at: start_at,
      end_at: end_at,
      facility_ids: [facility.id],
      approval_state: 'request')
  end
  let!(:item2) do
    create(
      :gws_schedule_facility_plan,
      start_at: start_at.advance(hours: -2),
      end_at: end_at.advance(hours: -2),
      facility_ids: [facility.id],
      approval_state: 'request')
  end
  let!(:item3) do
    create(
      :gws_schedule_facility_plan,
      start_at: start_at.advance(hours: 2),
      end_at: end_at.advance(hours: 2),
      facility_ids: [facility.id],
      approval_state: 'request')
  end

  let(:index_path) { gws_facility_schedule_path site }
  let(:plans_path) { gws_facility_plans_path site, state: "loan" }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      visit index_path

      first(".fc-event .fc-title", text: item1.name).click
      within ".gws-popup" do
        click_on I18n.t("ss.links.show")
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        within "span[data-facility-id='#{facility.id}']" do
          first("input[value='approve']").click
        end
      end
      wait_for_cbox do
        within "#ajax-box form#item-form" do
          fill_in "comment[text]", with: unique_id
          click_on I18n.t("ss.buttons.save")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      visit index_path
      first(".fc-event .fc-title", text: item2.name).click
      within ".gws-popup" do
        click_on I18n.t("ss.links.show")
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        within "span[data-facility-id='#{facility.id}']" do
          first("input[value='approve']").click
        end
      end
      wait_for_cbox do
        within "#ajax-box form#item-form" do
          fill_in "comment[text]", with: unique_id
          click_on I18n.t("ss.buttons.save")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      visit index_path
      first(".fc-event .fc-title", text: item3.name).click
      within ".gws-popup" do
        click_on I18n.t("ss.links.show")
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        within "span[data-facility-id='#{facility.id}']" do
          first("input[value='approve']").click
        end
      end
      wait_for_cbox do
        within "#ajax-box form#item-form" do
          fill_in "comment[text]", with: unique_id
          click_on I18n.t("ss.buttons.save")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      visit index_path
      expect(page).to have_css(".on-loan", text: I18n.t("gws/facility.views.on_loan"))
      within ".calendar-multiple-header" do
        click_on I18n.t("gws/facility.views.on_loan")
      end
      wait_for_cbox do
        expect(page).to have_css("table td", text: item1.name)
        expect(page).to have_css("table td", text: item2.name)
      end

      visit plans_path
      expect(page).to have_css(".list-item .state", text: I18n.t("gws/facility.options.loan_state.on_loan"))
      expect(page).to have_css(".list-item .state", text: I18n.t("gws/facility.options.loan_state.overdue"))

      expect(page).to have_css(".list-item .title", text: item1.name)
      expect(page).to have_css(".list-item .title", text: item2.name)
      expect(page).to have_no_css(".list-item .title", text: item3.name)

      click_on item1.name
      within ".mod-gws-schedule-facility_loan" do
        click_on I18n.t("ss.links.return")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.returned'))

      visit plans_path
      expect(page).to have_no_css(".list-item .title", text: item1.name)
      expect(page).to have_css(".list-item .title", text: item2.name)
      expect(page).to have_no_css(".list-item .title", text: item3.name)

      click_on item2.name
      within ".mod-gws-schedule-facility_loan" do
        click_on I18n.t("ss.links.return")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.returned'))

      visit plans_path
      expect(page).to have_no_css(".list-item .title", text: item1.name)
      expect(page).to have_no_css(".list-item .title", text: item2.name)
      expect(page).to have_no_css(".list-item .title", text: item3.name)

      visit index_path
      expect(page).to have_no_css(".on-loan", text: I18n.t("gws/facility.views.on_loan"))
    end
  end
end
