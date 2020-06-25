class Garbage::DescriptionsController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Garbage::Node::Description

  navi_view "garbage/description_lists/nav"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end
end