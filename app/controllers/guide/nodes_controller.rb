class Guide::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Guide::Node::Guide

  navi_view "cms/node/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def set_items
    @items = @model.site(@cur_site).
      node(@cur_node).
      allow(:read, @cur_user, site: @cur_site)
  end
end
