class Chat::LineBot::Session
  include SS::Document
  include SS::Reference::Site
  include Cms::Reference::Node
  include Cms::SitePermission

  field :userId, type: String
  field :date_created, type: String

  validates :userId, uniqueness: { scope: :date_created }
end