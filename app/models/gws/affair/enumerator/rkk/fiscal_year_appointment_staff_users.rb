class Gws::Affair::Enumerator::Rkk::FiscalYearAppointmentStaffUsers < Gws::Affair::Enumerator::Base
  def initialize(prefs, users, params)
    @prefs = prefs
    @users = users
    @params = params

    super() do |y|
      y << bom + encode(headers.to_csv)

      @prefs.each do |user_id, all_values|
        user = users.select { |user| user.id == user_id }.first

        all_values.each do |capital_id, values|
          next if capital_id == 0
          enum_record(y, user, capital_id, values)
        end
      end
    end
  end

  def headers
    I18n.t("gws/rkk.export.overtime.fiscal_year_appointment_staff").to_a
  end

  private

  def enum_record(yielder, user, capital_id, values)
    line = []
    yielder << encode(line.to_csv)
  end

  def format_minute(minute)
    hours = minute / 60
    minutes = minute % 60

    hours += 1 if minutes >= 30
    hours
  end
end
