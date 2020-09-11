module Gws::Addon::User::StaffCategory
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :staff_category, type: String
    permit_params :staff_category
  end
end
