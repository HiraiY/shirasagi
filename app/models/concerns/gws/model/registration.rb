module Gws::Model::Registration
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site

  included do

    attr_accessor :in_password
    attr_accessor :in_password_again
    attr_accessor :email_again
    attr_accessor :sends_verification_mail
    attr_accessor :in_check_email_again
    attr_accessor :in_check_name
    attr_accessor :in_check_password
    attr_accessor :in_protocol, :in_host
    attr_accessor :decrypted_password

    seqid :id
    field :name, type: String
    field :email, type: String
    field :email_type, type: String
    field :password, type: String
    field :state, type: String
    field :token, type: String
    field :expiration_date, type: DateTime

    permit_params :name, :email, :email_again, :email_type, :password, :in_password, :in_password_again, :state
    permit_params :token, :expiration_date
    permit_params :sends_verification_mail

    validates :email, email: true, length: { maximum: 80 }
    validates :email, presence: true
    validate :validate_email_again, if: ->{ in_check_email_again }
    validates :name, presence: true, length: { maximum: 40 }, if: ->{ in_check_name }
    validates :password, presence: true, if: ->{ in_check_password }
    validate :validate_password, if: ->{ in_check_password }

    before_validation :encrypt_password, if: ->{ in_password.present? }

    after_save :send_verification_mail

    scope :and_temporary, -> { where(state: 'temporary') }
    scope :and_token, ->(token) { where(token: token.to_s)}
  end

  def encrypt_password
    self.password = SS::Crypt.crypt(in_password)
  end

  private

  def send_verification_mail
    Gws::Registration::Mailer.verification_mail(self, in_protocol, in_host).deliver_now if self.sends_verification_mail == 'yes'
  end

  def validate_email_again
    if email_again.blank?
      errors.add :email_again, :blank
      return
    end

    if email.present? && email != email_again
      errors.add :email, :mismatch
    end
  end

  def validate_password
    validator = Sys::Setting.password_validator
    return if validator.blank?
    validator.validate(self)
  end
end
