module Guide::Addon
  module Procedure
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :procedures, class_name: "Guide::Procedure"

      permit_params procedure_ids: []
    end
  end
end
