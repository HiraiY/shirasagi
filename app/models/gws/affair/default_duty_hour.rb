class Gws::Affair::DefaultDutyHour
  include ActiveModel::Model
  include Gws::SitePermission

  set_permission_name "gws_affair_duty_hours"

  attr_accessor :cur_site

  def new_record?
    false
  end

  def persisted?
    true
  end

  def destroyed?
    false
  end

  def id
    "default"
  end

  def name
    I18n.t("gws/affair.default_duty_hour")
  end

  def addons
    []
  end

  def lookup_addons
  end

  def method_missing(name, *args, &block)
    if cur_site.respond_to?(name)
      return cur_site.send(name, *args, &block)
    end

    super
  end

  def respond_to_missing?(name, include_private)
    return true if cur_site.respond_to?(name, include_private)

    super
  end

  def affair_start(time)
    time.change(hour: affair_start_at_hour, min: affair_start_at_minute, sec: 0)
  end

  def affair_end(time)
    time.change(hour: affair_end_at_hour, min: affair_end_at_minute, sec: 0)
  end

  def affair_next_changed(time)
    hour = attendance_time_changed_minute / 60
    changed = time.change(hour: hour, min: 0, sec: 0)
    (time > changed) ? changed.advance(days: 1) : changed
  end

  def night_time_start(time)
    hour = SS.config.gws.affair.dig("overtime", "night_time", "start_hour")
    time.change(hour: 0, min: 0, sec: 0).advance(hours: hour)
  end

  def night_time_end(time)
    hour = SS.config.gws.affair.dig("overtime", "night_time", "end_hour")
    time.change(hour: 0, min: 0, sec: 0).advance(hours: hour)
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
    false
  end
end
