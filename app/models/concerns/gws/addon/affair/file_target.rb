module Gws::Addon::Affair::FileTarget
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    belongs_to :target_user, class_name: 'Gws::User'
    belongs_to :target_group, class_name: 'Gws::Group'

    permit_params :target_user_id
    permit_params :target_group_id

    validates :target_user_id, presence: true
    validates :target_group_id, presence: true
  end
end
