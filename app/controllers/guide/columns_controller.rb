class Guide::ColumnsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Guide::Column
  navi_view "cms/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t("guide.column"), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end
end
