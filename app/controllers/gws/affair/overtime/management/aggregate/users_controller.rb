class Gws::Affair::Overtime::Management::Aggregate::UsersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::Overtime::AggregateFilter

  model Gws::Affair::OvertimeDayResult

  navi_view "gws/affair/main/navi"
  menu_view nil

  before_action :set_query

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t("modules.gws/affair/overtime_file/management/aggregate"), gws_affair_overtime_management_aggregate_users_main_path]
    @crumbs << [t("modules.gws/affair/overtime_file/management/aggregate/user"), gws_affair_overtime_management_aggregate_users_main_path]
  end

  def set_query
    @current = Time.zone.now
    @threshold = params[:threshold]

    @year = (params.dig(:s, :year).presence || @current.year).to_i
    @month = (params.dig(:s, :month).presence || @current.month).to_i
    @group_id = params.dig(:s, :group_id).presence
    @capital_id = params.dig(:s, :capital_id).presence

    @s = OpenStruct.new
    @s[:year] = @year
    @s[:month] = @month
    @s[:capital_id] = @capital_id
    @s[:group_id] = @group_id
  end

  def set_items
    @groups = Gws::Group.in_group(@cur_site).active

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

    @items = @model.site(@cur_site).and(cond).user_aggregate
  end

  public

  def index
    set_items
    set_time_cards
  end

  def download
    return if request.get?

    set_download_params
    set_items
    enum_csv = Gws::Affair::Enumerator::OvertimeDayResult.new(@items, @users, @threshold, @download_params)
    send_enum(enum_csv,
      type: "text/csv; charset=#{@download_params.encoding}",
      filename: "aggregate_#{@threshold}_#{Time.zone.now.to_i}.csv"
    )
  end
end
