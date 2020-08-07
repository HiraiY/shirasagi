require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example, js: true do
  # 勤務体系は 8:30 - 17:15 | 3:00

  let(:site) { gws_site }
  let(:day_0830) { Time.zone.parse("2020/8/30") } #平日
  let(:day_0831) { Time.zone.parse("2020/8/31") } #平日
  let(:day_0901) { Time.zone.parse("2020/9/1") } #平日
  let(:reason_type) { I18n.t("gws/attendance.options.reason_type.mistake") }
  let(:memo) { unique_id }

  def punch_enter(now)
    expect(page).to have_css('.today-box .today .info .enter', text: '--:--')
    within '.today-box .today .action .enter' do
      page.accept_confirm do
        click_on I18n.t('gws/attendance.buttons.punch')
      end
    end
    expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))

    hour = now.hour > 3 ? now.hour : now.hour + 24
    min = now.min
    expect(page).to have_css('.today-box .today .info .enter', text: format('%d:%02d', hour, min))
    dump("enter")
  end

  def punch_leave(now)
    expect(page).to have_css('.today-box .today .info .leave', text: '--:--')
    within '.today-box .today .action .leave' do
      page.accept_confirm do
        click_on I18n.t('gws/attendance.buttons.punch')
      end
    end
    expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))

    hour = now.hour > 3 ? now.hour : now.hour + 24
    min = now.min
    expect(page).to have_css('.today-box .today .info .leave', text: format('%d:%02d', hour, min))
  end

  def punch_yesterday_leave(now)
    expect(page).to have_css('.yesterday-box .today .info .leave', text: '--:--')
    within '.yesterday-box .today .action .leave' do
      page.accept_confirm do
        click_on I18n.t('gws/attendance.buttons.punch')
      end
    end
    expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))

    hour = now.hour > 3 ? now.hour : now.hour + 24
    min = now.min
    expect(page).to have_css('.yesterday-box .today .info .leave', text: format('%d:%02d', hour, min))
  end

  def check_time_card_leave(date, now)
    Gws::Attendance::TimeCard.where(date: date.change(day: 1).beginning_of_day).first.tap do |time_card|
      expect(time_card.records.where(date: date).count).to eq 1
      time_card.records.where(date: date).first.tap do |record|
        expect(record.date).to eq date
        expect(record.leave).to eq now
      end
    end
  end

  def check_time_card_enter(date, now)
    Gws::Attendance::TimeCard.where(date: date.change(day: 1).beginning_of_day).first.tap do |time_card|
      expect(time_card.records.where(date: date).count).to eq 1
      time_card.records.where(date: date).first.tap do |record|
        expect(record.date).to eq date
        expect(record.enter).to eq now
      end
    end
  end

=begin
  context 'edit enter' do
    context 'edit at 8/31 8:10' do
      let(:now) { day_0901.change(hour: 8, min: 10) }
      let(:yesterday) { now.yesterday }

      it do
        Timecop.freeze(yesterday) do
          login_gws_user
          visit gws_affair_attendance_time_card_main_path(site)

          expect(page).to have_css('.yesterday-box .today .enter [name="punch"][disabled]')
          expect(page).to have_css('.yesterday-box .today .leave [name="punch"][disabled]')

          punch_enter(yesterday)
          punch_leave(yesterday)

          check_time_card_leave(day_0831, yesterday)
          check_time_card_enter(day_0831, yesterday)
        end

        Timecop.freeze(now) do
          login_gws_user
          visit gws_affair_attendance_time_card_main_path(site)

          expect(page).to have_css('.yesterday-box .today .enter [name="punch"][disabled]')
          expect(page).to have_css('.yesterday-box .today .leave [name="punch"][disabled]')
        end
      end

      it do
        Timecop.freeze(yesterday) do
          login_gws_user
          visit gws_affair_attendance_time_card_main_path(site)

          expect(page).to have_css('.yesterday-box .today .enter [name="punch"][disabled]')
          expect(page).to have_css('.yesterday-box .today .leave [name="punch"][disabled]')

          punch_enter(yesterday)

          check_time_card_enter(day_0831, yesterday)
        end

        Timecop.freeze(now) do
          login_gws_user
          visit gws_affair_attendance_time_card_main_path(site)

          expect(page).to have_css('.yesterday-box .today .enter [name="punch"][disabled]')

          punch_yesterday_leave(now)
        end
      end
    end
  end
=end
end
