class Gws::Affair::Overtime::Management::Aggregate::UsersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair::OvertimeDayResult

  navi_view "gws/affair/main/navi"
  menu_view nil

  before_action :set_query

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t("modules.gws/affair/overtime_file/management/aggregate/user"), gws_affair_overtime_management_aggregate_users_main_path]
    if params[:threshold] == "under"
      @crumbs << ["通常分", gws_affair_overtime_management_aggregate_users_path(threshold: "under")]
    elsif params[:threshold] == "over"
      @crumbs << ["割合引上対象分", gws_affair_overtime_management_aggregate_users_path(threshold: "over")]
    elsif params[:threshold] == "total"
      @crumbs << ["時間外合計", gws_affair_overtime_management_aggregate_users_path(threshold: "over")]
    end
  end

  def set_query
    @current = Time.zone.now

    @groups = Gws::Group.in_group(@cur_site).active
    @year = (params.dig(:s, :year).presence || @current.year).to_i
    @month = (params.dig(:s, :month).presence || @current.month).to_i
    @group_id = params.dig(:s, :group_id).presence
    @capital_id = params.dig(:s, :capital_id).presence

    @s ||= OpenStruct.new params[:s]
    @s[:year] ||= @year
    @s[:month] ||= @month
    @s[:capital_id] = @capital_id
  end

  def set_items
    @threshold = params[:threshold]

    if @group_id.present?
      group = @groups.where(id: @group_id).first
    else
      group = @cur_user.gws_main_group(@cur_site)
    end
    group ||= @cur_site
    @s[:group_id] ||= group.id

    @users = Gws::User.active.in(group_ids: [group.id]).order_by_title(@cur_site)

    # only not flextime users
    @users = @users.select do |user|
      duty_calendar = user.effective_duty_calendar(@cur_site)
      !duty_calendar.flextime?
    end

    user_ids = @users.pluck(:id)

    cond = [
      { "date_year" => @year },
      { "date_month" => @month },
      { "user_id" => { "$in" => user_ids } }
    ]

    if @capital_id.present?
      cond << { "capital_id" => @capital_id.to_i }
    end

    @items = @model.site(@cur_site).and(cond).user_aggregate
  end

  def set_time_cards
    @unlocked_time_cards = []
    date = Time.new(@year, @month, 1, 0, 0, 0).in_time_zone
    @users.each do |user|
      title = I18n.t(
        'gws/attendance.formats.time_card_full_name',
        user_name: user.name, month: I18n.l(date.to_date, format: :attendance_year_month)
      )
      time_card = Gws::Attendance::TimeCard.site(@cur_site).user(user).where(date: date).first
      if !time_card || !time_card.locked?
        @unlocked_time_cards << title
      end
    end
  end

  public

  def index
    set_items
    set_time_cards
  end

  def download
    return if request.get?

    safe_params = params.require(:s).permit(:encoding)
    encoding = safe_params[:encoding]
    filename = "aggregate_#{@threshold}_#{Time.zone.now.to_i}.csv"

    set_items
    enum_csv = Gws::Affair::OvertimeDayResultEnumerator.new(@items, @users, @threshold, OpenStruct.new(encoding: encoding))
    send_enum(enum_csv, type: "text/csv; charset=#{encoding}", filename: filename)
  end
end
