module Garbage::Addon
  module Description
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :category, type: String
      field :style, type: String
      field :bgcolor, type: String

      permit_params :category, :style, :bgcolor
    end
  end
end