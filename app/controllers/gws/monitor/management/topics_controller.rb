class Gws::Monitor::Management::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Monitor::TopicFilter
  include Gws::Memo::NotificationFilter

  before_action :check_readable
  navi_view "gws/monitor/main/navi"

  private

  # override Gws::Monitor::TopicFilter#append_view_paths
  def append_view_paths
    append_view_path 'app/views/gws/monitor/management/main'
    super
  end

  def set_crumbs
    set_category
    @crumbs << [@cur_site.menu_monitor_label || t("modules.gws/monitor"), gws_monitor_topics_path]
    @crumbs << [t('gws/monitor.tabs.management_topic'), action: :index, category: '-']
    if @category.present?
      @crumbs << [@category.name, action: :index, category: @category]
    end
  end

  def set_items
    @items = @model.site(@cur_site).topic
    @items = @items.allow(:read, @cur_user, site: @cur_site)
    @items = @items.without_deleted
    @items = @items.search(@s)
    @items = @items.custom_order(@s.sort)
    @items = @items.page(params[:page]).per(50)
  end

  def check_readable
    if @item
      raise '403' unless @item.allowed?(:read, @cur_user, site: @cur_site)
    end
  end

  public

  # override Gws::Monitor::TopicFilter#show
  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)

    render file: "show_#{@item.mode}"
  end

  def edit
    raise "404" if @item.public?
    super
  end

  def update
    raise "404" if @item.public?
    super
  end

  def soft_delete
    set_item unless @item
    raise "404" if @item.public?
    super
  end
end
