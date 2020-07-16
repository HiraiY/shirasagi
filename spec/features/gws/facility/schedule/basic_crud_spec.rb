require 'spec_helper'

describe "gws_facility_schedule", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  let(:start_at) { Time.zone.now.change(min: 0, sec: 0) }
  let(:end_at) { start_at.advance(hours: 1) }

  let(:facility) { create :gws_facility_item, approval_check_state: "enabled", loan_state: "enabled", user_ids: [user.id] }
  let!(:item) do
    create(
      :gws_schedule_facility_plan,
      start_at: start_at,
      end_at: end_at,
      facility_ids: [facility.id],
      approval_state: 'request')
  end
  let(:index_path) { gws_facility_schedule_path site }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      visit index_path

      wait_for_ajax
      within ".calendar-name" do
        expect(page).to have_content(facility.name)
      end
    end

    it "#edit" do
      visit index_path

      within ".fc-event" do
        first(".fc-title").click
      end
      within ".gws-popup" do
        click_on I18n.t("ss.links.edit")
      end

      within "form#item-form" do
        fill_in "item[start_at]", with: end_at
        fill_in "item[end_at]", with: end_at.advance(hours: 1)
      end
      within ".gws-schedule-facility" do
        expect(page).to have_css("td", text: facility.name)
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))
    end

    # 承認された設備予約の変更はできない
    it "#edit" do
      visit index_path

      within ".fc-event" do
        first(".fc-title").click
      end
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

      within ".fc-event" do
        first(".fc-title").click
      end
      within ".gws-popup" do
        click_on I18n.t("ss.links.edit")
      end

      within "form#item-form" do
        fill_in "item[start_at]", with: end_at
        fill_in "item[end_at]", with: end_at.advance(hours: 1)
      end
      within ".gws-schedule-facility" do
        expect(page).to have_css("td", text: facility.name)
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#errorExplanation', text: I18n.t("gws/schedule.errors.on_loan_faciliy"))
    end
  end
end
