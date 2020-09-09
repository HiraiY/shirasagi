module Gws::Affair::DutyHourSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    attr_accessor :in_attendance_time_change_hour

    field :attendance_time_changed_minute, type: Integer, default: 3 * 60

    field :affair_start_at_hour, type: Integer, default: 9
    field :affair_start_at_minute, type: Integer, default: 0
    field :affair_end_at_hour, type: Integer, default: 18
    field :affair_end_at_minute, type: Integer, default: 0
    field :affair_time_wday, default: "disabled"

    (0..6).each do |wday|
      field "affair_start_at_hour_#{wday}", type: Integer, default: 9
      field "affair_start_at_minute_#{wday}", type: Integer, default: 0
      field "affair_end_at_hour_#{wday}", type: Integer, default: 18
      field "affair_end_at_minute_#{wday}", type: Integer, default: 0
      permit_params "affair_start_at_hour_#{wday}", "affair_start_at_minute_#{wday}"
      permit_params "affair_end_at_hour_#{wday}", "affair_end_at_minute_#{wday}"
    end

    field :affair_on_duty_working_minute, type: Integer
    field :affair_on_duty_break_minute, type: Integer
    field :affair_overtime_working_minute, type: Integer
    field :affair_overtime_break_minute, type: Integer

    field :overtime_in_work, type: String, default: "disabled"

    permit_params :in_attendance_time_change_hour
    permit_params :affair_time_wday
    permit_params :affair_on_duty_working_minute, :affair_on_duty_break_minute
    permit_params :affair_overtime_working_minute, :affair_overtime_break_minute
    permit_params :overtime_in_work

    before_validation :set_attendance_time_changed_minute

    validates :affair_start_at_hour, presence: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
    validates :affair_start_at_minute, presence: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 59 }
    validates :affair_end_at_hour, presence: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
    validates :affair_end_at_minute, presence: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 59 }
  end

  def affair_time_wday?
    affair_time_wday == "enabled"
  end

  def affair_start_at_hour_options
    (0..23).map do |h|
      [ "#{h}#{I18n.t('datetime.prompts.hour')}", h.to_s ]
    end
  end

  def affair_end_at_hour_options
    (0..23).map do |h|
      [ "#{h}#{I18n.t('datetime.prompts.hour')}", h.to_s ]
    end
  end

  def affair_start_at_minute_options
    0.step(59, 5).map do |h|
      [ "#{h}#{I18n.t('datetime.prompts.minute')}", h.to_s ]
    end
  end

  def affair_end_at_minute_options
    0.step(59, 5).map do |h|
      [ "#{h}#{I18n.t('datetime.prompts.minute')}", h.to_s ]
    end
  end

  def overtime_in_work_options
    [
      [I18n.t("ss.options.state.enabled"), "enabled"],
      [I18n.t("ss.options.state.disabled"), "disabled"],
    ]
  end

  (0..6).each do |wday|
    alias_method "affair_start_at_hour_#{wday}_options", "affair_start_at_hour_options"
    alias_method "affair_start_at_minute_#{wday}_options", "affair_start_at_minute_options"
    alias_method "affair_end_at_hour_#{wday}_options", "affair_end_at_hour_options"
    alias_method "affair_end_at_minute_#{wday}_options", "affair_end_at_minute_options"
  end

  def affair_start_at_hour(time = nil)
    return super() unless time
    affair_time_wday? ? send("affair_start_at_hour_#{time.wday}") : affair_start_at_hour
  end

  def affair_start_at_minute(time = nil)
    return super() unless time
    affair_time_wday? ? send("affair_start_at_minute_#{time.wday}") : affair_start_at_minute
  end

  def affair_end_at_hour(time = nil)
    return super() unless time
    affair_time_wday? ? send("affair_end_at_hour_#{time.wday}") : affair_end_at_hour
  end

  def affair_end_at_minute(time = nil)
    return super() unless time
    affair_time_wday? ? send("affair_end_at_minute_#{time.wday}") : affair_end_at_minute
  end

  def attendance_time_changed_options
    (0..23).map do |h|
      [ "#{h}#{I18n.t('datetime.prompts.hour')}", h.to_s ]
    end
  end

  def calc_attendance_date(time = Time.zone.now)
    Time.zone.at(time.to_i - attendance_time_changed_minute * 60).beginning_of_day
  end

  def affair_start(time)
    hour = affair_start_at_hour(time)
    min = affair_start_at_minute(time)
    time.change(hour: hour, min: min, sec: 0)
  end

  def affair_end(time)
    hour = affair_end_at_hour(time)
    min = affair_end_at_minute(time)
    time.change(hour: hour, min: min, sec: 0)
  end

  def affair_next_changed(time)
    hour = attendance_time_changed_minute / 60
    changed = time.change(hour: hour, min: 0, sec: 0)
    (time > changed) ? changed.advance(days: 1) : changed
  end

  def night_time_start(time)
    hour = SS.config.gws.affair.dig("overtime", "night_time", "start_hour")
    time.change(hour: 0, min: 0, sec: 0)
    time.advance(hours: hour)
  end

  def night_time_end(time)
    hour = SS.config.gws.affair.dig("overtime", "night_time", "end_hour")
    time.change(hour: 0, min: 0, sec: 0)
    time.advance(hours: hour)
  end

  def working_minute(time)
    start_at = affair_start(time)
    end_at = affair_end(time)
    return 0 if start_at >= end_at

    duty_working_minute = affair_on_duty_working_minute.to_i
    duty_break_minute = affair_on_duty_break_minute.to_i

    minutes = ((end_at.to_datetime - start_at.to_datetime) * 24 * 60).to_i
    if duty_working_minute > 0 && minutes > duty_working_minute
      break_minute = duty_break_minute * (minutes / duty_working_minute)
      minutes -= break_minute
    end

    minutes = 0 if minutes < 0
    minutes
  end

  def overtime_in_work?
    overtime_in_work == "enabled"
  end

  private

  def set_attendance_time_changed_minute
    if in_attendance_time_change_hour.blank?
      self.attendance_time_changed_minute = 3 * 60
    else
      self.attendance_time_changed_minute = Integer(in_attendance_time_change_hour) * 60
    end
  end
end
