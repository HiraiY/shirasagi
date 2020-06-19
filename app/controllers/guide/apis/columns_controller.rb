class Guide::Apis::ColumnsController < ApplicationController
  include Cms::ApiFilter

  model Guide::Column

  def index
    @multi = params[:single].blank?

    @items = @model.site(@cur_site).
      search(params[:s]).
      order_by(order: 1, updated: -1).
      page(params[:page]).per(50)
  end
end
