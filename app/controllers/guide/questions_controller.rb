class Guide::QuestionsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Guide::Question
  navi_view "cms/node/main/navi"

  private

  def set_crumbs
    @crumbs << [t("guide.question"), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end
end
