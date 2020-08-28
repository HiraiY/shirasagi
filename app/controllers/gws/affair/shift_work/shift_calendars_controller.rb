class Gws::Affair::ShiftWork::ShiftCalendarsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair::ShiftCalendar

  navi_view "gws/affair/main/navi"

  before_action :set_user, except: :index
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]

  private

  def set_user
    @user = Gws::User.find(params[:user])
  end

  def get_params
    fix_params
  end

  def pre_params
    { cur_site: @cur_site, user: @user }
  end

  def fix_params
    { cur_site: @cur_site, user: @user }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path ]
    @crumbs << [ t("modules.gws/affair/shift_calendar"), gws_affair_shift_work_shift_calendars_path ]
  end

  def set_query
    @s ||= OpenStruct.new params[:s]
    group_id = params.dig(:s, :group_id).presence

    @groups = Gws::Group.in_group(@cur_site).active

    if group_id.present?
      @group = @groups.where(id: group_id).first
    else
      @group = @cur_user.gws_main_group(@cur_site)
    end
    @group ||= @cur_site

    # 所属グループ権限のみの場合は自グループのみ
    if !@model.allowed_other?(:edit, @cur_user, site: @cur_site)
      @groups = [@group]
    end

    @users = Gws::User.active.in(group_ids: [@group.id]).order_by_title(@cur_site)

    @s[:group_id] ||= @group.id
  end

  def crud_redirect_url
    url_for(action: :index)
  end

  public

  def index
    set_query
  end
end
