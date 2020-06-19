class Guide::ProceduresController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Guide::Procedure
  navi_view "cms/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t("guide.procedure"), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end
end
