module Gws::Addon::Registration::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :registration_sender_name, type: String
    field :registration_sender_email, type: String
    belongs_to :registration_sender_user, class_name: 'SS::User'

    permit_params :registration_sender_name, :registration_sender_email, :registration_sender_user_id

    validates :registration_sender_email, email: true
  end

  def registration_sender_address
    @sender_address ||= begin
      if registration_sender_user.present? && registration_sender_user.active? && registration_sender_user.email.present?
        "#{registration_sender_user.name} <#{registration_sender_user.email}>"
      elsif registration_sender_email.present?
        if registration_sender_name.present?
          "#{registration_sender_name} <#{registration_sender_email}>"
        else
          registration_sender_email
        end
      else
        SS.config.mail.default_from
      end
    end
  end

  def registration_receiver_address
    @receiver_address ||= begin
      if registration_sender_user.present? && registration_sender_user.active? && registration_sender_user.email.present?
        registration_sender_user.email
      elsif registration_sender_email.present?
          registration_sender_email
      else
        SS.config.mail.default_from
      end
    end
  end
end