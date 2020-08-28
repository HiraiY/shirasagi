class Gws::Affair::Overtime::Management::Aggregate::RkkController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::Overtime::AggregateFilter

  model Gws::Affair::OvertimeDayResult

  navi_view "gws/affair/main/navi"
  menu_view nil

  before_action :set_query

  private

  def set_query
    @current = Time.zone.now

    @year = (params.dig(:s, :year).presence || @current.year).to_i
    @month = (params.dig(:s, :month).presence || @current.month).to_i

    @s = OpenStruct.new
    @s[:year] = @year
    @s[:month] = @month
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t("modules.gws/affair/overtime_file/management/aggregate"), gws_affair_overtime_management_aggregate_search_main_path]
    @crumbs << [t("modules.gws/affair/overtime_file/management/aggregate/rkk"), gws_affair_overtime_management_aggregate_rkk_download_path]
  end

  public

  def download
    return if request.get?

    set_download_params
    @groups = Gws::Group.in_group(@cur_site).active.to_a
    @users = Gws::User.active.in(group_ids: @groups.map(&:id)).order_by_title(@cur_site)

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

    dump(@items)

    enum_csv = Gws::Affair::Enumerator::Rkk::RegularUsers.new(@items, @users, @download_params)
    send_enum(enum_csv,
      type: "text/csv; charset=#{@download_params.encoding}",
      filename: "aggregate_#{@threshold}_#{Time.zone.now.to_i}.csv"
    )
  end
end
