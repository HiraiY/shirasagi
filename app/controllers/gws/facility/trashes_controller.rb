class Gws::Facility::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter
  include Gws::Memo::NotificationFilter

  navi_view 'gws/facility/main/navi'

  menu_view 'gws/crud/menu'

  self.destroy_notification_actions = []
  self.destroy_all_notification_actions = []

  private

  def set_items
    @items ||= begin
      Gws::Schedule::Plan.site(@cur_site).only_deleted.
        allow(:trash, @cur_user, site: @cur_site).
        search(params[:s])
    end
  end

  public

  def index
    @items = @items.
      order_by(start_at: -1).
      page(params[:page]).per(50)
  end
end