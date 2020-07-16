class Gws::Facility::FacilityPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Facility::FacilityPlanFilter
  include Gws::Memo::NotificationFilter

  navi_view "gws/facility/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_facility_label || t('modules.gws/facility'), gws_facility_main_path]
    @crumbs << [t('modules.addons.gws/schedule/facility'), gws_facility_schedule_path]
  end
end
