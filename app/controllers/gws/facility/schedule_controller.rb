class Gws::Facility::ScheduleController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Facility::PlanFilter

  def show
    @facility = Gws::Facility::Item.site(@cur_site).find(params[:facility])
  end

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/facility'), gws_facility_main_path]
    @crumbs << [t('modules.addons.gws/schedule/facility'), gws_facility_schedule_path]
  end

  navi_view "gws/facility/main/navi"
end
