class Faq::Agents::Nodes::TagsController < ApplicationController
  include Cms::PageFilter::View

  private
    def pages
      Faq::Page.site(@cur_site).and_public(@cur_date).and(@cur_node.condition_hash)
    end

  public
    def index
      @search_node = @cur_node.find_search_node
      @aggregation = pages.grouped_tag_list
    end
end
