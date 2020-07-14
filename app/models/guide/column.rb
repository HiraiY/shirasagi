class Guide::Column
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  seqid :id

  belongs_to :question, class_name: 'Guide::Question'

  field :name, type: String
  field :order, type: Integer, default: 0
end
