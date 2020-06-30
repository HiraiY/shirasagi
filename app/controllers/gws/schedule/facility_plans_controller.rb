class Gws::Schedule::FacilityPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Facility::FacilityPlanFilter
  include Gws::Memo::NotificationFilter

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('modules.addons.gws/schedule/facility'), gws_schedule_facilities_path]
  end

  navi_view "gws/schedule/main/navi"
end
