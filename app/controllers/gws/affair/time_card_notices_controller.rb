class Gws::Affair::TimeCardNoticesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair::TimeCardNotice

  navi_view "gws/affair/main/navi"

  before_action :set_duty_calendar
  before_action :set_crumbs

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, duty_calendar: @duty_calendar }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path ]
    @crumbs << [ t("modules.gws/affair/duty_calendar"), gws_affair_duty_calendars_path ]
    @crumbs << [ @duty_calendar.name, gws_affair_duty_calendar_path(id: @duty_calendar) ]
  end

  def set_duty_calendar
    @duty_calendar = Gws::Affair::DutyCalendar.find(params[:duty_calendar_id])
  end

  public

  def index
    @items = @duty_calendar.time_card_notices
  end
end
