class Guide::Column
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Guide::Addon::Genre
  include Cms::Addon::GroupPermission

  set_permission_name "guide_procedures"

  seqid :id

  belongs_to :question, class_name: 'Guide::Question'

  field :select_options_id, type: String
  field :name, type: String
  field :order, type: Integer, default: 0
end
