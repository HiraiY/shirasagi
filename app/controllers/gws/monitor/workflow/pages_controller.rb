class Gws::Monitor::Workflow::PagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Workflow::PagesFilter

  private

  def set_model
    @model = Gws::Monitor::Post
  end
end
