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

  let(:name) { unique_id }

  context "with auth", js: true do
    before { login_gws_user }

    # 申請中の予定は同じ時間に重複して登録可能
    it "#index" do
      visit index_path

      wait_for_ajax
      within ".calendar-name" do
        expect(page).to have_content(facility.name)
      end
      expect(page).to have_css(".approval-check", text: I18n.t("gws/facility.views.required_approval"))

      click_on I18n.t("gws/schedule.links.add_plan")

      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        fill_in "item[start_at]", with: start_at
        fill_in "item[end_at]", with: end_at
      end
      within ".gws-schedule-facility" do
        expect(page).to have_css("td", text: facility.name)
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      plans = Gws::Schedule::Plan.site(site).in(facility_ids: [facility.id]).to_a
      expect(plans.size).to eq 2
      expect(plans.map(&:approval_state)).to match_array %w(request request)
    end

    # 承認された予定があれば、同じ時間に予定を登録不可
    it "#index" do
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

      plans = Gws::Schedule::Plan.site(site).in(facility_ids: [facility.id]).to_a
      expect(plans.size).to eq 1
      expect(plans.map(&:approval_state)).to match_array %w(approve)

      click_on I18n.t('ss.links.back_to_index')

      click_on I18n.t("gws/schedule.links.add_plan")

      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        fill_in "item[start_at]", with: start_at
        fill_in "item[end_at]", with: end_at
      end
      within ".gws-schedule-facility" do
        expect(page).to have_css("td", text: facility.name)
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_cbox do
        expect(page).to have_content(I18n.t("gws/schedule.facility_reservation.exist"))
      end
    end

    # 承認された予定があっても、別の時間に予定を登録可能
    it "#index" do
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

      plans = Gws::Schedule::Plan.site(site).in(facility_ids: [facility.id]).to_a
      expect(plans.size).to eq 1
      expect(plans.map(&:approval_state)).to match_array %w(approve)

      click_on I18n.t('ss.links.back_to_index')

      click_on I18n.t("gws/schedule.links.add_plan")

      within "form#item-form" do
        fill_in "item[name]", with: unique_id
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

      plans = Gws::Schedule::Plan.site(site).in(facility_ids: [facility.id]).to_a
      expect(plans.size).to eq 2
      expect(plans.map(&:approval_state)).to match_array %w(approve request)
    end

    # 同じ時間に別々の予定があり、承認状態にできるのは一つだけ
    it "#index" do
      visit index_path

      click_on I18n.t("gws/schedule.links.add_plan")

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[start_at]", with: start_at
        fill_in "item[end_at]", with: end_at
      end
      within ".gws-schedule-facility" do
        expect(page).to have_css("td", text: facility.name)
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      # 最初の予定を承認
      visit index_path
      first(".fc-event .fc-title", text: item.name).click
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

      # 次の予定を承認
      visit index_path
      first(".fc-event .fc-title", text: name).click
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

      plans = Gws::Schedule::Plan.site(site).in(facility_ids: [facility.id]).to_a
      expect(plans.size).to eq 2
      expect(plans.map(&:approval_state)).to match_array %w(approve request)

      # 最初の予定の承認を変更
      visit index_path
      first(".fc-event .fc-title", text: item.name).click
      within ".gws-popup" do
        click_on I18n.t("ss.links.show")
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        within "span[data-facility-id='#{facility.id}']" do
          first("input[value='deny']").click
        end
      end
      wait_for_cbox do
        within "#ajax-box form#item-form" do
          fill_in "comment[text]", with: unique_id
          click_on I18n.t("ss.buttons.save")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # 次の予定の承認を変更
      visit index_path
      first(".fc-event .fc-title", text: name).click
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

      plans = Gws::Schedule::Plan.site(site).in(facility_ids: [facility.id]).to_a
      expect(plans.size).to eq 2
      expect(plans.map(&:approval_state)).to match_array %w(approve deny)
    end
  end
end
