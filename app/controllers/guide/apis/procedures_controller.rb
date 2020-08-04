class Guide::Apis::ProceduresController < ApplicationController
  include Cms::ApiFilter

  model Guide::Procedure

  def index
    @multi = params[:single].blank?

    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site, node: @cur_node).
      search(params[:s]).
      order_by(order: 1, name: 1).
      page(params[:page]).per(50)
  end
end
