class Guide::GenresController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Guide::Node::Genre

  navi_view "cms/node/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end
end
