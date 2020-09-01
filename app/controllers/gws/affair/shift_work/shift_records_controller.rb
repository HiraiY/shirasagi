class Gws::Affair::ShiftWork::ShiftRecordsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair::ShiftRecord

  navi_view "gws/affair/main/navi"

  before_action :set_cur_month
  before_action :set_user
  before_action :set_shift_calendar
  before_action :set_crumbs

  private

  def fix_params
    { shift_calendar: @shift_calendar }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path ]
    @crumbs << [ t("modules.gws/affair/shift_calendar"), gws_affair_shift_work_shift_calendars_path ]
    @crumbs << [ @user.name, gws_affair_shift_work_shift_calendar_shift_records_path ]
  end

  def set_cur_month
    @cur_year = params[:year].to_i
    @cur_month = params[:month].to_i
    @cur_date = Time.zone.parse("#{@cur_year}/#{@cur_month}/01")
  end

  def set_user
    @user = Gws::User.find(params[:user])
  end

  def set_shift_calendar
    @shift_calendar = Gws::Affair::ShiftCalendar.find(params[:shift_calendar_id])
  end

  public

  def index
  end

  def download
    enum = @model.enum_csv(@shift_calendar, @cur_year)
    send_enum enum, type: 'text/csv; charset=Shift_JIS',
      filename: "shift_records_#{Time.zone.now.strftime("%Y_%m%d_%H%M")}.csv"
  end

  def import
    @item = @model.new
    return if request.get?

    @item.attributes = get_params
    result = @item.import_csv
    flash.now[:notice] = t("ss.notice.saved") if result
    render_create result, location: { action: :index }, render: { file: :import }
  end
end
