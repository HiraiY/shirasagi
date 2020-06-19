module Guide
  class Initializer
    Cms::Node.plugin "guide/node"

    Cms::Role.permission :read_guide_procedures
    Cms::Role.permission :edit_guide_procedures
    Cms::Role.permission :delete_guide_procedures
  end
end
