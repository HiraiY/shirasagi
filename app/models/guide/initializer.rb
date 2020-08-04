module Guide
  class Initializer
    Cms::Node.plugin "guide/node"
    Cms::Node.plugin "guide/genre"
    Cms::Node.plugin "guide/guide"

    Cms::Part.plugin "guide/node"

    Cms::Role.permission :read_other_guide_procedures
    Cms::Role.permission :read_private_guide_procedures
    Cms::Role.permission :edit_other_guide_procedures
    Cms::Role.permission :edit_private_guide_procedures
    Cms::Role.permission :delete_other_guide_procedures
    Cms::Role.permission :delete_private_guide_procedures
    Cms::Role.permission :import_other_guide_procedures
    Cms::Role.permission :import_private_guide_procedures
  end
end
