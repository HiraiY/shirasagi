class Gws::Workflow::PagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Workflow::PagesFilter
end
