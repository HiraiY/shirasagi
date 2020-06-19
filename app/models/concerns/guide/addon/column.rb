module Guide::Addon
  module Column
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :applicable_columns, class_name: "Guide::Column"
      embeds_ids :not_applicable_columns, class_name: "Guide::Column"

      permit_params applicable_column_ids: [], not_applicable_column_ids: []
    end
  end
end
