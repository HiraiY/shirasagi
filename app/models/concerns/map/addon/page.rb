module Map::Addon
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_points, type: Map::Extensions::Points, default: []
      field :map_zoom_level, type: Integer
      field :map_link, type: String, default: "hide"
      permit_params map_points: [ :name, :loc, :text, :link, :image, :number ]
      permit_params :map_zoom_level, :map_link

      if respond_to? :liquidize
        liquidize do
          export :map_points
          export :map_zoom_level
        end
      end
    end

    def map_link_options
      %w(hide show).map do |v|
        [ I18n.t("map.#{v}"), v ]
      end
    end

    def map_url
      if self.map_points.present?
        url = "https://www.google.co.jp/maps/dir/"
        map_points = self.map_points.sort_by! { |map_point| map_point[:number] }
        map_points.each do |map_point|
          next if map_point[:number].blank?
          url += map_point[:loc].join(',') + "/"
        end
        url
      end
    end
  end
end
