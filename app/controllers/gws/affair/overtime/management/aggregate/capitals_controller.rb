class Gws::Affair::Overtime::Management::Aggregate::CapitalsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::Overtime::AggregateFilter

  model Gws::Affair::OvertimeDayResult

  navi_view "gws/affair/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t("modules.gws/affair/overtime_file/management/aggregate"), gws_affair_overtime_management_aggregate_capitals_main_path]
    @crumbs << [t("modules.gws/affair/overtime_file/management/aggregate/capital"), gws_affair_overtime_management_aggregate_capitals_main_path]
  end

  def set_year_month
    @year = params[:year].to_i
    @month = params[:month].to_i
  end

  def set_groups
    @group = Gws::Group.find(params[:group])

    groups = Gws::Group.active.where(name: /^#{@group.name}\//).to_a
    @children = groups.select { |g| g.depth == @group.depth + 1 }
    @descendants = {}
    @descendants[@group.id] = groups
    groups.each do |g1|
      @descendants[g1.id] = groups.select { |g2| g2.name =~ /^#{g1.name}\// }
    end

    @groups = @children.present? ? @children : [@group]
  end

  def set_users
    @users = Gws::User.active.in(group_ids: [@group.id]).order_by_title(@cur_site).to_a

    # only not flextime users
    @users = @users.select do |user|
      duty_calendar = user.effective_duty_calendar(@cur_site)
      !duty_calendar.flextime?
    end
  end

  def set_dates
    beginning_of_fiscal_year = Time.zone.parse("#{@year}/#{@cur_site.attendance_year_changed_month}/1")
    @dates = (0..11).map { |m| beginning_of_fiscal_year.advance(months: m) }
  end

  public

  def index
    set_year_month
    set_dates

    @group = @cur_site
    @title = I18n.t("gws/affair.labels.overtime.capitals.title", year: @year)
    @capitals = Gws::Affair::Capital.site(@cur_site)
    @items = @model.site(@cur_site).capital_aggregate_by_month
  end

  def groups
    set_year_month
    set_groups
    set_users

    @title = I18n.t("gws/affair.labels.overtime.capitals.title_groups", year: @year, month: @month, group: @group.name)
    @capitals = Gws::Affair::Capital.site(@cur_site)
    @items = @model.site(@cur_site).where(date_year: @year, date_month: @month).capital_aggregate_by_group
  end

  def users
    set_year_month
    set_groups
    set_users
    set_time_cards

    @title = I18n.t("gws/affair.labels.overtime.capitals.title_users", year: @year, month: @month, group: @group.name)
    @capitals = Gws::Affair::Capital.site(@cur_site)
    @items = @model.site(@cur_site).where(date_year: @year, date_month: @month).capital_aggregate_by_users
  end

  def download
    set_year_month
    set_dates

    return if request.get?

    set_download_params

    @title = I18n.t("gws/affair.labels.overtime.capitals.title", year: @year)
    @group = @cur_site
    @capitals = Gws::Affair::Capital.site(@cur_site)
    @items = @model.site(@cur_site).where(date_year: @year).capital_aggregate_by_month

    enum_csv = Gws::Affair::Enumerator::Capital.new(@items, @title, @capitals, @dates, @download_params)
    send_enum(enum_csv,
      type: "text/csv; charset=#{@download_params.encoding}",
      filename: "aggregate_capitals_#{Time.zone.now.to_i}.csv"
    )
  end

  def download_groups
    set_year_month

    return if request.get?

    set_download_params
    set_groups
    set_users

    @title = I18n.t("gws/affair.labels.overtime.capitals.title_groups", year: @year, month: @month, group: @group.name)
    @capitals = Gws::Affair::Capital.site(@cur_site)
    @items = @model.site(@cur_site).where(date_year: @year, date_month: @month).capital_aggregate_by_group

    enum_csv = Gws::Affair::Enumerator::CapitalGroups.new(@items, @title, @capitals, @groups, @descendants, @download_params)
    send_enum(enum_csv,
      type: "text/csv; charset=#{@download_params.encoding}",
      filename: "aggregate_capitals_#{Time.zone.now.to_i}.csv"
    )
  end

  def download_users
    set_year_month

    return if request.get?

    set_download_params
    set_groups
    set_users

    @title = I18n.t("gws/affair.labels.overtime.capitals.title_users", year: @year, month: @month, group: @group.name)
    @capitals = Gws::Affair::Capital.site(@cur_site)
    @items = @model.site(@cur_site).where(date_year: @year, date_month: @month).capital_aggregate_by_users

    enum_csv = Gws::Affair::Enumerator::CapitalUsers.new(@items, @title, @capitals, @users, @download_params)
    send_enum(enum_csv,
      type: "text/csv; charset=#{@download_params.encoding}",
      filename: "aggregate_capitals_#{Time.zone.now.to_i}.csv"
    )
  end
end
