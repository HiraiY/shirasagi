class Facility::Map
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include Workflow::Addon::Approver
  include Cms::Addon::Meta
  include Map::Addon::Page
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission

  default_scope ->{ where(route: "facility/map") }
  validate :center_position_validate, if: -> { set_center_position.present? }

  private

  def serve_static_file?
    false
  end

  def center_position_validate
    latlon = set_center_position.split(',').map(&:to_f)
    lat = latlon[0]
    lon = latlon[1]
    unless lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180
      self.errors.add :set_center_position, :invalid_latlon
    end
  end
end
