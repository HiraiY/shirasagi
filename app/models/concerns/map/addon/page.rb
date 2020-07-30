module Map::Addon
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_points, type: Map::Extensions::Points, default: []
      field :map_zoom_level, type: Integer
      field :map_link, type: String, default: "hide"
      field :map_goal, type: Integer
      field :map_route, type: String

      permit_params map_points: [ :name, :loc, :text, :link, :image, :number ]
      permit_params :map_zoom_level, :map_link, :map_goal, :map_route

      validate :validate_number
      validate :validate_map_goal
      validate :validate_map_route

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

    def set_map_url
      if self.map_points.present?
        url = "https://www.google.co.jp/maps/dir/"
        if self.map_route.present?
          self.map_route.split(',').each do |route|
            map_points.each do |map_point|
              url += map_point[:loc].join(',') + "/" if route == map_point[:number]
            end
          end
        else
          map_points = self.map_points.sort_by! { |map_point| map_point[:number].to_i }
          map_points.each do |map_point|
            next if map_point[:number].blank?
            url += map_point[:loc].join(',') + "/"
          end
          if self.map_goal.present?
            map_points.each do |map_point|
              url += map_point[:loc].join(',') + "/" if map_point[:number] == self.map_goal.to_s
            end
          end
        end
        url
      end
    end

    def validate_number
      if self.map_points.present?
        self.map_points.uniq.group_by { |e| e[:number] }.map do |n, m|
          if n.numeric? && m.length > 1
            return self.errors.add :map_points, :uniq_number
          end
        end
      end
    end

    def validate_map_goal
      if self.map_goal.present?
        if self.map_points.select { |x| x[:number].include?(self.map_goal.to_s) }.blank?
          return self.errors.add :map_goal, :invalid
        end
      end
    end

    def validate_map_route
      if self.map_route.present?
        self.map_route.split(',').each do |n|
          return self.errors.add :map_route, :invalid if !n.numeric?
          return self.errors.add :map_route, :invalid if self.map_points.find_all { |x| x[:number].include?(n) }.blank?
        end
      end
    end
  end
end
