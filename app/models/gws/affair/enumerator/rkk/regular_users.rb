class Gws::Affair::Enumerator::Rkk::RegularUsers < Gws::Affair::Enumerator::Base
  def initialize(prefs, users, params)
    @prefs = prefs
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
    I18n.t("gws/rkk.export.overtime.regular").to_a
  end

  private

  def enum_record(yielder, user)
    under_duty_day    = @prefs.dig(user.id, "under_threshold", "duty_day_time_minute").to_i
    under_duty_night  = @prefs.dig(user.id, "under_threshold", "duty_night_time_minute").to_i
    under_leave_day   = @prefs.dig(user.id, "under_threshold", "leave_day_time_minute").to_i
    under_leave_night = @prefs.dig(user.id, "under_threshold", "leave_night_time_minute").to_i
    under_week_out    = @prefs.dig(user.id, "under_threshold", "week_out_compensatory_minute").to_i

    over_duty_day    = @prefs.dig(user.id, "over_threshold", "duty_day_time_minute").to_i
    over_duty_night  = @prefs.dig(user.id, "over_threshold", "duty_night_time_minute").to_i
    over_leave_day   = @prefs.dig(user.id, "over_threshold", "leave_day_time_minute").to_i
    over_leave_night = @prefs.dig(user.id, "over_threshold", "leave_night_time_minute").to_i
    over_week_out    = @prefs.dig(user.id, "over_threshold", "week_out_compensatory_minute").to_i

    # under_duty_day    1.25
    # under_duty_night  1.5
    # under_leave_day   1.35
    # under_leave_night 1.6
    # under_week_out    0.25
    #
    # over_duty_day     1.5
    # over_duty_night   1.75
    # over_leave_day    1.5
    # over_leave_night  1.75
    # over_week_out     0.5

    line = []
    line << "10"
    line << user.organization_uid
    line << ""
    line << under_duty_day
    line << under_duty_night + under_duty_night + over_leave_day
    line << under_leave_day
    line << under_leave_night
    line << under_week_out
    line << over_duty_night + over_leave_night
    line << over_week_out
    line << 0

    yielder << encode(line.to_csv)
  end
end
