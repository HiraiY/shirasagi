module Gws::Addon::Registration::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :approver_name, type: String
    field :approver_email, type: String

    belongs_to :approver, class_name: 'SS::User'
    belongs_to :default_group, class_name: "SS::Group"

    embeds_ids :groups, class_name: "Gws::Group"
    embeds_ids :default_roles, class_name: "Gws::Role"

    permit_params :approver_name, :approver_email
    permit_params :approver_id, :default_group_id, default_role_ids: []

    validates :set_approver_email, email: true
  end

  def set_approver_email
    @approver_email ||= begin
      if approver.present? && approver.active? && approver.email.present?
        approver.email
      elsif approver_email.present?
        approver_email
      else
        SS.config.mail.default_from
      end
    end
  end

  def set_sender_email
    @sender_email ||= begin
      if sender_user.present? && sender_user.active? && sender_user.email.present?
        sender_user.email
      elsif sender_email.present?
        sender_email
      else
        SS.config.mail.default_from
      end
    end
  end
end