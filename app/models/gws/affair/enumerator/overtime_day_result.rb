class Gws::Affair::Enumerator::OvertimeDayResult < Gws::Affair::Enumerator::Base
  def initialize(prefs, users, threshold, params)
    @prefs = prefs
    @threshold = threshold
    @users = users
    @params = params

    super() do |y|
      y << bom + encode(headers.to_csv)
      @users.each do |user|
        enum_record(y, user)
      end
    end
  end

  def headers
    line = []
    if @threshold == "total"
      line << Gws::User.t(:name)
      line << Gws::User.t(:organization_uid)
      line << I18n.t("gws/affair.labels.overtime.total.under")
      line << I18n.t("gws/affair.labels.overtime.total.over")
      line << I18n.t("gws/affair.labels.overtime.total.sum")
    else
      line << Gws::User.t(:name)
      line << Gws::User.t(:organization_uid)
      line << I18n.t("gws/affair.labels.overtime.#{@threshold}_threshold.duty_day_time.rate")
      line << I18n.t("gws/affair.labels.overtime.#{@threshold}_threshold.duty_night_time.rate")
      line << I18n.t("gws/affair.labels.overtime.#{@threshold}_threshold.leave_day_time.rate")
      line << I18n.t("gws/affair.labels.overtime.#{@threshold}_threshold.leave_night_time.rate")
      line << I18n.t("gws/affair.labels.overtime.#{@threshold}_threshold.week_out_compensatory.rate")
    end
    line
  end

  private

  def enum_record(yielder, user)
    line = []
    line << user.long_name
    line << user.organization_uid

    if @threshold == "total"
      total_under_minutes = @prefs.dig(user.id, "under_threshold", "overtime_minute").to_i
      total_over_minutes = @prefs.dig(user.id, "over_threshold", "overtime_minute").to_i
      overtime_minute = total_under_minutes + total_over_minutes

      line << format_minute(total_under_minutes)
      line << format_minute(total_over_minutes)
      line << format_minute(overtime_minute)
    else
      duty_day_time_minute = @prefs.dig(user.id, "#{@threshold}_threshold", "duty_day_time_minute")
      duty_night_time_minute = @prefs.dig(user.id, "#{@threshold}_threshold", "duty_night_time_minute")
      leave_day_time_minute = @prefs.dig(user.id, "#{@threshold}_threshold", "leave_day_time_minute")
      leave_night_time_minute = @prefs.dig(user.id, "#{@threshold}_threshold", "leave_night_time_minute")
      week_out_compensatory_minute = @prefs.dig(user.id, "#{@threshold}_threshold", "week_out_compensatory_minute")

      line << format_minute(duty_day_time_minute)
      line << format_minute(duty_night_time_minute)
      line << format_minute(leave_day_time_minute)
      line << format_minute(leave_night_time_minute)
      line << format_minute(week_out_compensatory_minute)
    end

    yielder << encode(line.to_csv)
  end
end
