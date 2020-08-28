class Gws::Affair::Overtime::Management::Aggregate::SearchController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::Overtime::AggregateFilter

  model Gws::Affair::OvertimeDayResult

  navi_view "gws/affair/main/navi"

  before_action :set_query

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t("modules.gws/affair/overtime_file/management/aggregate"), gws_affair_overtime_management_aggregate_search_main_path]
    @crumbs << [t("modules.gws/affair/overtime_file/management/aggregate/search"), gws_affair_overtime_management_aggregate_search_main_path]
  end

  def set_query
    @current = Time.zone.now

    @year = (params.dig(:s, :year).presence || @current.year).to_i
    @month = (params.dig(:s, :month).presence || @current.month).to_i
    @user_ids = params.dig(:s, :user_ids).to_a.select(&:present?).map(&:to_i)
    @group_ids = params.dig(:s, :group_ids).to_a.select(&:present?).map(&:to_i)

    @s = OpenStruct.new
    @s[:year] = @year
    @s[:month] = @month
    @s[:user_ids] = @user_ids
    @s[:group_ids] = @group_ids
  end

  public

  def users
    @users = Gws::User.active.in(id: @user_ids).to_a
  end

  def users_results
    @users = Gws::User.active.in(id: @user_ids).to_a
    @capitals = Gws::Affair::Capital.site(@cur_site)
    @items = @model.site(@cur_site).where(date_year: @year, date_month: @month).capital_aggregate_by_users

    set_time_cards
  end

  def groups
    @groups = Gws::Group.active.in(id: @group_ids).to_a
  end

  def groups_results
    @group = @cur_site
    groups = Gws::Group.active.where(name: /^#{@group.name}\//).to_a

    @descendants = {}
    @descendants[@group.id] = groups
    groups.each do |g1|
      @descendants[g1.id] = groups.select { |g2| g2.name =~ /^#{g1.name}\// }
    end

    @groups = Gws::Group.active.in(id: @group_ids).to_a
    @capitals = Gws::Affair::Capital.site(@cur_site)
    @items = @model.site(@cur_site).where(date_year: @year, date_month: @month).capital_aggregate_by_group
  end

  def download_groups
    return if request.get?

    @group = @cur_site
    groups = Gws::Group.active.where(name: /^#{@group.name}\//).to_a

    @descendants = {}
    @descendants[@group.id] = groups
    groups.each do |g1|
      @descendants[g1.id] = groups.select { |g2| g2.name =~ /^#{g1.name}\// }
    end

    set_download_params

    @title = I18n.t("gws/affair.labels.overtime.capitals.title_search", year: @year, month: @month)
    @groups = Gws::Group.active.in(id: @group_ids).to_a
    @capitals = Gws::Affair::Capital.site(@cur_site)
    @items = @model.site(@cur_site).where(date_year: @year, date_month: @month).capital_aggregate_by_group

    @download_params[:total] = false
    enum_csv = Gws::Affair::Enumerator::CapitalGroups.new(@items, @title, @capitals, @groups, @descendants, @download_params)
    send_enum(enum_csv,
      type: "text/csv; charset=#{@download_params.encoding}",
      filename: "aggregate_capitals_#{Time.zone.now.to_i}.csv"
    )
  end

  def download_users
    return if request.get?

    set_download_params

    @title = I18n.t("gws/affair.labels.overtime.capitals.title_search", year: @year, month: @month)
    @users = Gws::User.active.in(id: @user_ids).to_a
    @capitals = Gws::Affair::Capital.site(@cur_site)
    @items = @model.site(@cur_site).where(date_year: @year, date_month: @month).capital_aggregate_by_users

    enum_csv = Gws::Affair::Enumerator::CapitalUsers.new(@items, @title, @capitals, @users, @download_params)
    send_enum(enum_csv,
      type: "text/csv; charset=#{@download_params.encoding}",
      filename: "aggregate_capitals_#{Time.zone.now.to_i}.csv"
    )
  end
end
