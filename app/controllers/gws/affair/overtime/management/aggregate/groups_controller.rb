class Gws::Affair::Overtime::Management::Aggregate::GroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair::OvertimeDayResult

  navi_view "gws/affair/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t("modules.gws/affair/overtime_file/management/aggregate/capital"), gws_affair_overtime_management_aggregate_groups_main_path]
  end

  def set_year_month
    @cur_year = params[:year].to_i
    @cur_month = params[:month].to_i
  end

  def set_items
  end

  def set_time_cards
  end

  public

  def index
    set_year_month

    @items = @model.site(@cur_site).aggregate_by_month
    @capitals = Gws::Affair::Capital.site(@cur_site)
  end

  def monthly
    set_year_month

    @capitals = Gws::Affair::Capital.site(@cur_site)
    @items = @model.site(@cur_site).where(date_year: @cur_year, date_month: @cur_month).aggregate_by_group

    groups = Gws::Group.where(name: /^#{@cur_site.name}\//).active
    @groups = groups.select { |g| g.depth == 1 }

    @descendants = {}
    groups.each do |g1|
      @descendants[g1.id] = groups.select { |g2| g2.name =~ /^#{g1.name}\// }
    end
  end

  def groups
    set_year_month

    @capitals = Gws::Affair::Capital.site(@cur_site)
    @items = @model.site(@cur_site).where(date_year: @cur_year, date_month: @cur_month).aggregate_by_group

    groups = Gws::Group.where(name: /^#{@cur_site.name}\//).active
    @groups = groups.select { |g| g.depth == 1 }

    @descendants = {}
    groups.each do |g1|
      @descendants[g1.id] = groups.select { |g2| g2.name =~ /^#{g1.name}\// }
    end

    @group = Gws::Group.find(params[:group])
    @descendant_groups = @descendants[@group.id] || []
  end

  def users
    set_year_month

    @capitals = Gws::Affair::Capital.site(@cur_site)
    @items = @model.site(@cur_site).where(date_year: @cur_year, date_month: @cur_month).aggregate_by_group_users

    @child_group = Gws::Group.find(params[:child_group])
    @users = Gws::User.active.in(group_ids: [@child_group.id]).order_by_title(@cur_site)
  end

  def download
  end
end
