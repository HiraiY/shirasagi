class Gws::Monitor::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Monitor::CommentFilter
  include Gws::Memo::NotificationFilter

  private

  def set_crumbs
    set_category
    set_topic

    @crumbs << [@cur_site.menu_monitor_label || t("modules.gws/monitor"), gws_monitor_main_path]
    @crumbs << [t('gws/monitor.tabs.topic'), gws_monitor_topics_path(category: '-')]
    if @category.present?
      @crumbs << [@category.name, gws_monitor_topics_path(category: @category)]
    end
    @crumbs << [@topic.name, gws_monitor_topic_path(category: @category || '-', id: @topic)]
  end
end
