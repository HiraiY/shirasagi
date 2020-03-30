class Chat::LineBot::Phrase
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  field :name, type: String
  field :frequency, type: Integer, default: 0
end