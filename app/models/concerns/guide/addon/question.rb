module Guide::Addon
  module Question
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :questions, class_name: "Guide::Question"
      embeds_ids :columns, class_name: "Guide::Column"

      permit_params question_ids: [], column_ids: []
    end
  end
end
