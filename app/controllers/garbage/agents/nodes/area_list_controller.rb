class Garbage::Agents::Nodes::AreaListController < ApplicationController
  include Cms::NodeFilter::View
  helper Garbage::ListHelper

  def index
  end
end
