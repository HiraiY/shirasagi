module Cms::Addon
  module AccessCount
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :access_count, type: Integer

      permit_params :access_count
    end
  end
end
