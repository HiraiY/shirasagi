module Gws::Addon::Affair::OvertimeFile
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_accessor :start_at_date, :start_at_hour, :start_at_minute
    attr_accessor :end_at_date, :end_at_hour, :end_at_minute
    attr_accessor :week_in_start_at_date, :week_in_start_at_hour, :week_in_start_at_minute
    attr_accessor :week_in_end_at_date, :week_in_end_at_hour, :week_in_end_at_minute
    attr_accessor :week_out_start_at_date, :week_out_start_at_hour, :week_out_start_at_minute
    attr_accessor :week_out_end_at_date, :week_out_end_at_hour, :week_out_end_at_minute

    field :overtime_name, type: String
    field :date, type: DateTime
    field :start_at, type: DateTime
    field :end_at, type: DateTime
    field :week_in_start_at, type: DateTime
    field :week_in_end_at, type: DateTime
    field :week_out_start_at, type: DateTime
    field :week_out_end_at, type: DateTime

    field :week_in_compensatory_minute, type: Integer, default: 0
    field :week_out_compensatory_minute, type: Integer, default: 0
    field :remark, type: String

    permit_params :overtime_name
    permit_params :start_at_date, :start_at_hour, :start_at_minute
    permit_params :end_at_date, :end_at_hour, :end_at_minute
    permit_params :week_in_start_at_date, :week_in_start_at_hour, :week_in_start_at_minute
    permit_params :week_in_end_at_date, :week_in_end_at_hour, :week_in_end_at_minute
    permit_params :week_out_start_at_date, :week_out_start_at_hour, :week_out_start_at_minute
    permit_params :week_out_end_at_date, :week_out_end_at_hour, :week_out_end_at_minute

    permit_params :week_in_compensatory_minute
    permit_params :week_out_compensatory_minute
    permit_params :remark

    before_validation :validate_date
    before_validation :set_name_by_term
    before_validation :validate_week_in_date
    before_validation :validate_week_out_date
    before_validation :validate_week_in_compensatory_minute
    before_validation :validate_compensatory_minute

    validates :overtime_name, presence: true
    validates :start_at, presence: true, datetime: true
    validates :end_at, presence: true, datetime: true

    after_initialize do
      if start_at
        self.start_at_date = start_at.strftime("%Y/%m/%d")
        self.start_at_hour = start_at.hour
        self.start_at_minute = start_at.minute
      end

      if end_at
        self.end_at_date = end_at.strftime("%Y/%m/%d")
        self.end_at_hour = end_at.hour
        self.end_at_minute = end_at.minute
      end

      if week_in_start_at
        self.week_in_start_at_date = week_in_start_at.strftime("%Y/%m/%d")
        self.week_in_start_at_hour = week_in_start_at.hour
        self.week_in_start_at_minute = week_in_start_at.minute
      end

      if week_in_end_at
        self.week_in_end_at_date = week_in_end_at.strftime("%Y/%m/%d")
        self.week_in_end_at_hour = week_in_end_at.hour
        self.week_in_end_at_minute = week_in_end_at.minute
      end

      if week_out_start_at
        self.week_out_start_at_date = week_out_start_at.strftime("%Y/%m/%d")
        self.week_out_start_at_hour = week_out_start_at.hour
        self.week_out_start_at_minute = week_out_start_at.minute
      end

      if week_out_end_at
        self.week_out_end_at_date = week_out_end_at.strftime("%Y/%m/%d")
        self.week_out_end_at_hour = week_out_end_at.hour
        self.week_out_end_at_minute = week_out_end_at.minute
      end
    end
  end

  def start_at_hour_options
    (0..23).map { |h| [ "#{h}#{I18n.t('datetime.prompts.hour')}", h.to_s ] }
  end

  def start_at_minute_options
    # (0..59).select { |m| m % 5 == 0 }.map { |m| [ "#{m}#{I18n.t('datetime.prompts.minute')}", m.to_s ] }
    0.step(59, 5).map { |m| [ "#{m}#{I18n.t('datetime.prompts.minute')}", m.to_s ] }
  end

  def end_at_hour_options
    (0..23).map { |h| [ "#{h}#{I18n.t('datetime.prompts.hour')}", h.to_s ] }
  end

  def end_at_minute_options
    # (0..59).select { |m| m % 5 == 0 }.map { |m| [ "#{m}#{I18n.t('datetime.prompts.minute')}", m.to_s ] }
    0.step(59, 5).map { |m| [ "#{m}#{I18n.t('datetime.prompts.minute')}", m.to_s ] }
  end

  def week_in_compensatory_minute_options
    I18n.t("gws/affair.options.compensatory_minute").map { |k, v| [v, k] }
  end

  def week_out_compensatory_minute_options
    I18n.t("gws/affair.options.compensatory_minute").map { |k, v| [v, k] }
  end

  def validate_date
    return if start_at_date.blank? || start_at_hour.blank? || start_at_minute.blank?
    return if end_at_date.blank? || end_at_hour.blank? || end_at_minute.blank?

    site = self.site || cur_site

    # 作成者ではなく申請者の勤務時間を確認する
    user = target_user

    return if site.blank?
    return if user.blank?

    self.start_at = Time.zone.parse("#{start_at_date} #{start_at_hour}:#{start_at_minute}")
    self.end_at = Time.zone.parse("#{end_at_date} #{end_at_hour}:#{end_at_minute}")

    if start_at >= end_at
      errors.add :end_at, :greater_than, count: t(:start_at)
    end

    duty_calendar = user.effective_duty_calendar(site)

    changed_at = duty_calendar.affair_next_changed(start_at)
    self.date = changed_at.advance(days: -1).change(hour: 0, min: 0, sec: 0)

    #if end_at > changed_at
    #  errors.add :base, :over_change_hour
    #end
    if end_at >= start_at.advance(days: 1)
      errors.add :base, :over_one_day
    end

    return if duty_calendar.leave_day?(date)

    affair_start = duty_calendar.affair_start(start_at)
    affair_end = duty_calendar.affair_end(start_at)
    in_affair_at1 = end_at > affair_start && start_at < affair_end

    affair_start = duty_calendar.affair_start(end_at)
    affair_end = duty_calendar.affair_end(end_at)
    in_affair_at2 = end_at > affair_start && start_at < affair_end

    if in_affair_at1 || in_affair_at2
      errors.add :base, :in_duty_hour
    end
  end

  def validate_week_in_date
    if week_in_compensatory_minute == 0
      self.week_in_start_at = nil
      self.week_in_end_at = nil
    else
      self.week_in_start_at = Time.zone.parse("#{week_in_start_at_date} #{week_in_start_at_hour}:#{week_in_start_at_minute}")
      self.week_in_end_at = Time.zone.parse("#{week_in_end_at_date} #{week_in_end_at_hour}:#{week_in_end_at_minute}")

      if week_in_start_at >= week_in_end_at
        errors.add :week_in_end_at, :greater_than, count: t(:week_in_start_at)
      end

      if week_in_end_at >= week_in_start_at.advance(days: 1)
        errors.add :base, :over_one_day
      end

      if ((week_in_end_at - week_in_start_at) * 24 * 60).to_i != week_in_compensatory_minute
        errors.add :week_in_compensatory_minute, :not_match_compensatory_minute_and_hour
      end
    end
  end

  def validate_week_out_date
    if week_out_compensatory_minute == 0
      self.week_out_start_at = nil
      self.week_out_end_at = nil
    else
      self.week_out_start_at = nil if week_out_start_at_date.blank?
      self.week_out_end_at = nil if week_out_end_at_date.blank?

      if week_out_start_at_date.present? && week_out_end_at_date.present?
        self.week_out_start_at = Time.zone.parse("#{week_out_start_at_date} #{week_out_start_at_hour}:#{week_out_start_at_minute}")
        self.week_out_end_at = Time.zone.parse("#{week_out_end_at_date} #{week_out_end_at_hour}:#{week_out_end_at_minute}")

        if week_out_start_at >= week_out_end_at
          errors.add :week_out_end_at, :greater_than, count: t(:week_out_start_at)
        end

        if week_out_end_at >= week_out_start_at.advance(days: 1)
          errors.add :base, :over_one_day
        end

        if ((week_out_end_at - week_out_start_at) * 24 * 60).to_i != week_out_compensatory_minute
          errors.add :week_out_compensatory_minute, :not_match_compensatory_minute_and_hour
        end
      elsif week_out_start_at_date.present? && week_out_end_at_date.blank?
        errors.add :week_out_end_at_date, :blank
      elsif week_out_start_at_date.blank? && week_out_end_at_date.present?
        errors.add :week_out_start_at_date, :blank
      end
    end
  end

  def validate_week_in_compensatory_minute
    if week_in_compensatory_minute > 0 && week_in_start_at_date.blank?
      errors.add :week_in_start_at, :blank
    end
    if week_in_compensatory_minute > 0 && week_in_end_at_date.blank?
      errors.add :week_in_end_at, :blank
    end
  end

  def validate_compensatory_minute
    if week_in_compensatory_minute > 0 && week_out_compensatory_minute > 0
      errors.add :week_out_compensatory_minute, :not_set_week_out_compensatory_minute
    end
  end

  def start_end_term
    start_time = "#{start_at.hour}:#{format('%02d', start_at.minute)}"
    end_time = "#{end_at.hour}:#{format('%02d', end_at.minute)}"
    if start_at_date == end_at_date
      "#{start_at.strftime("%Y/%m/%d")} #{start_time}#{I18n.t("ss.wave_dash")}#{end_time}"
    else
      "#{start_at.strftime("%Y/%m/%d")} #{start_time}#{I18n.t("ss.wave_dash")}#{end_at.strftime("%Y/%m/%d")} #{end_time}"
    end
  end

  def week_in_start_end_term
    week_in_start_time = "#{week_in_start_at.hour}:#{format('%02d', week_in_start_at.minute)}"
    week_in_end_time = "#{week_in_end_at.hour}:#{format('%02d', week_in_end_at.minute)}"
    if week_in_start_at_date == end_at_date
      "#{week_in_start_at.strftime("%Y/%m/%d")} #{week_in_start_time}#{I18n.t("ss.wave_dash")}#{week_in_end_time}"
    else
      "#{week_in_start_at.strftime("%Y/%m/%d")} #{week_in_start_time}#{I18n.t("ss.wave_dash")}#{week_in_end_at.strftime("%Y/%m/%d")} #{week_in_end_time}"
    end
  end

  def week_out_start_end_term
    return if week_out_start_at.blank?
    week_out_start_time = "#{week_out_start_at.hour}:#{format('%02d', week_out_start_at.minute)}"
    week_out_end_time = "#{week_out_end_at.hour}:#{format('%02d', week_out_end_at.minute)}"
    if start_at_date == end_at_date
      "#{week_out_start_at.strftime("%Y/%m/%d")} #{week_out_start_time}#{I18n.t("ss.wave_dash")}#{week_out_end_time}"
    else
      "#{week_out_start_at.strftime("%Y/%m/%d")} #{week_out_start_time}#{I18n.t("ss.wave_dash")}#{week_out_end_at.strftime("%Y/%m/%d")} #{week_out_end_time}"
    end
  end

  def term_label
    "#{overtime_name}（#{start_end_term}）"
  end

  private

  def set_name_by_term
    return if overtime_name.blank?
    return if date.blank? || start_at.blank? || end_at.blank?
    return if name.present?

    self.name = term_label
  end
end
