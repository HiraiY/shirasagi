module Guide::Addon
  module Genre
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :genres, class_name: "Guide::Node::Genre", metadata: { on_copy: :safe }
      permit_params genre_ids: []
    end
  end
end
