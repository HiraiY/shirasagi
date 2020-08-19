class Gws::Affair::ShiftRecord
  include SS::Document
  include Gws::Affair::ShiftRecord::Export

  attr_accessor :start_at, :end_at

  belongs_to :shift_calendar, class_name: "Gws::Affair::ShiftCalendar"
  field :date, type: DateTime
  field :affair_start_at_hour, type: Integer
  field :affair_start_at_minute, type: Integer
  field :affair_end_at_hour, type: Integer
  field :affair_end_at_minute, type: Integer
  field :wday_type, type: String

  permit_params :affair_start_at_hour, :affair_start_at_minute
  permit_params :affair_end_at_hour, :affair_end_at_minute
  permit_params :wday_type

  validates :shift_calendar_id, presence: true
  validates :date, presence: true
  validates :affair_start_at_hour, presence: true
  validates :affair_start_at_minute, presence: true
  validates :affair_end_at_hour, presence: true
  validates :affair_end_at_minute, presence: true
  validates :wday_type, presence: true

  def affair_start_at_hour(time = nil)
    super()
  end

  def affair_start_at_minute(time = nil)
    super()
  end

  def affair_end_at_hour(time = nil)
    super()
  end

  def affair_end_at_minute(time = nil)
    super()
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

  def wday_type_options
    I18n.t("gws/affair.options.wday_type").map { |k, v| [v, k] }
  end

  def default_duty_hour
    shift_calendar.default_duty_calendar.default_duty_hour
  end

  def calc_attendance_date(time = Time.zone.now)
    default_duty_hour.calc_attendance_date(time)
  end

  def affair_start(time)
    time.change(hour: affair_start_at_hour, min: affair_start_at_minute, sec: 0)
  end

  def affair_end(time)
    time.change(hour: affair_end_at_hour, min: affair_end_at_minute, sec: 0)
  end

  def affair_next_changed(time)
    default_duty_hour.affair_next_changed(time)
  end

  def night_time_start(time)
    default_duty_hour.night_time_start(time)
  end

  def night_time_end(time)
    default_duty_hour.night_time_end(time)
  end

  def affair_on_duty_working_minute
    default_duty_hour.affair_on_duty_working_minute
  end

  def affair_on_duty_break_minute
    default_duty_hour.affair_on_duty_break_minute
  end

  #def affair_overtime_working_minute
  #  default_duty_hour.affair_overtime_working_minute
  #end

  #def affair_overtime_break_minute
  #  default_duty_hour.affair_overtime_break_minute
  #end

  #def working_minute(time)
  #  affair_on_duty_working_minute = default_duty_hour.affair_on_duty_working_minute
  #  affair_on_duty_break_minute = default_duty_hour.affair_on_duty_break_minute
  #
  #  start_at = Time.zone.parse("#{affair_start_at_hour}:#{affair_start_at_minute}").to_datetime
  #  end_at = Time.zone.parse("#{affair_end_at_hour}:#{affair_end_at_minute}").to_datetime
  #  return 0 if start_at >= end_at
  #
  #  minute = (end_at - start_at) * 24 * 64
  #  if affair_on_duty_working_minute && affair_on_duty_break_minute
  #    minute -= affair_on_duty_break_minute if minute > affair_on_duty_working_minute
  #  end
  #  minute
  #end

  def holiday?(date)
    wday_type == "holiday"
  end

  def leave_day?(date)
    wday_type == "holiday"
  end

  def flextime?
    duty_calendar.flextime?
  end

  def notices(time_card)
    duty_calendar.notices(time_card)
  end
end
