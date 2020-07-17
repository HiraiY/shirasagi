class Gws::Monitor::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Monitor::TopicFilter
  include Gws::Memo::NotificationFilter

  before_action :check_attended

  navi_view "gws/monitor/main/navi"

  private

  def set_crumbs
    set_category
    @crumbs << [@cur_site.menu_monitor_label || t("modules.gws/monitor"), gws_monitor_main_path]
    @crumbs << [t('gws/monitor.tabs.topic'), action: :index, category: '-']
    if @category.present?
      @crumbs << [@category.name, action: :index, category: @category]
    end
  end

  def set_search_params
    super
    @s.answer_state_filter ||= "unanswered"
    @s.approve_state_filter ||= params[:approve_state_filter] if params[:approve_state_filter].present?
  end

  def set_items
    @items = @model.site(@cur_site).topic
    @items = @items.and_public
    @items = @items.and_attended(@cur_user, site: @cur_site, group: @cur_group)
    @items = @items.without_deleted
    @items = @items.search(@s)
    @items = @items.custom_order(@s.sort)
    @items = @items.page(params[:page]).per(50)
  end

  def check_attended
    if @item
      raise '403' unless @item.attended?(@cur_group)
    end
  end
end
