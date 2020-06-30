class Gws::Facility::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Facility::Category

  navi_view "gws/facility/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_facility_label || t('modules.gws/facility'), gws_facility_main_path]
    @crumbs << [t('gws/facility.navi.category'), gws_facility_categories_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
