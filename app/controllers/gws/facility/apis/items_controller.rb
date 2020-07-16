class Gws::Facility::Apis::ItemsController < ApplicationController
  include Gws::ApiFilter
  include Gws::CrudFilter

  model Gws::Facility::Item
end
