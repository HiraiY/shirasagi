class Chat::LineBot::Session
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  field :user, type: String

  validates :user, uniqueness: true
end