class Guide::GuidesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Guide::Question

  navi_view "cms/node/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  public

  def index
    @procedures = @cur_node.becomes_with_route.procedures
    @questions = @model.site(@cur_site).
      # allow(:read, @cur_user, site: @cur_site, node: @cur_node).
      in(id: @procedures.pluck(:question_ids).flatten.uniq.compact)
    @items = @questions.search(params[:s]).
      page(params[:page]).per(50)
  end
end
