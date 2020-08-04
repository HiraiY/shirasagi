class Guide::Node
  include Cms::Model::Node
  include Cms::PluginRepository
  include Cms::Addon::NodeSetting
  include Cms::Addon::EditorSetting
  include Cms::Addon::GroupPermission
  include Cms::Addon::NodeAutoPostSetting
  include Cms::Addon::ForMemberNode

  index({ site_id: 1, filename: 1 }, { unique: true })

  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^guide\//) }
  end

  class Node
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Cms::Addon::EditorSetting
    include Cms::Addon::NodeAutoPostSetting
    include Cms::Addon::ForMemberNode
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "guide/node") }
  end

  class Genre
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Cms::Addon::EditorSetting
    include Cms::Addon::NodeAutoPostSetting
    include Cms::Addon::ForMemberNode
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "guide/genre") }

    def condition_hash(opts = {})
      h = super
      h['$or'] << { :genre_ids.in => [id] }
      h
    end
  end

  class Guide
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include ::Guide::Addon::Procedure
    include ::Guide::Addon::GuideList
    include ::Guide::Addon::Genre
    include Cms::Addon::EditorSetting
    include Cms::Addon::NodeAutoPostSetting
    include Cms::Addon::ForMemberNode
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "guide/guide") }
  end
end
