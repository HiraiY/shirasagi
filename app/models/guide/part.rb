class Guide::Part
  include Cms::Model::Part
  include Cms::PluginRepository

  index({ site_id: 1, filename: 1 }, { unique: true })

  plugin_type "part"

  class Base
    include Cms::Model::Part

    default_scope ->{ where(route: /^guide\//) }
  end

  class Node
    include Cms::Model::Part
    include ::Guide::Addon::Genre
    include Cms::Addon::NodeList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "guide/node") }

    def condition_hash(opts = {})
      h = super
      if genres.present?
        { "$and" => [ h, { :genre_ids.in => genre_ids } ] }
      else
        h
      end
    end
  end
end
