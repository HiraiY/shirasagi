module Gws::Model::Registration
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site

  included do

    attr_accessor :in_password
    attr_accessor :in_password_again
    attr_accessor :email_again
    attr_accessor :sends_notify_mail
    attr_accessor :sends_verification_mail
    attr_accessor :in_check_name
    attr_accessor :in_check_email_again
    attr_accessor :in_check_password
    attr_accessor :in_protocol, :in_host

    seqid :id
    field :name, type: String
    field :email, type: String
    field :email_type, type: String
    field :password, type: String
    field :state, type: String
    field :verification_mail_sent, type: DateTime
    field :notify_mail_sent, type: DateTime

    permit_params :name, :email, :email_again, :email_type, :password, :in_password, :in_password_again, :state
    permit_params :verification_mail_sent, :notify_mail_sent
    permit_params :sends_notify_mail, :sends_verification_mail

    validates :name, presence: true, length: { maximum: 40 }, if: ->{ in_check_name }
    validates :email, email: true, length: { maximum: 80 }
    validates :email, presence: true, if: ->{ email.present? }
    validates :email, uniqueness: { scope: :site_id }
    validate :validate_email_again, if: ->{ in_check_email_again }
    validates :email_type, inclusion: { in: %w(text html) }, if: ->{ email_type.present? }
    validates :password, presence: true, if: ->{ in_check_password }
    validate :validate_password, if: ->{ in_check_password }

    before_validation :encrypt_password, if: ->{ in_password.present? }

    # after_save :send_notify_mail
    after_save :send_verification_mail

    scope :and_temporary, -> { where(state: 'temporary') }
    scope :and_verification_token, ->(token) do
      email = SS::Crypt.decrypt(token) rescue nil
      where(email: email)
    end
  end

  def encrypt_password
    self.password = SS::Crypt.crypt(in_password)
  end

  def verification_token
    SS::Crypt.encrypt(email)
  end

  def email_type_options
    %w(text html).map { |m| [ I18n.t("cms.options.email_type.#{m}"), m ] }.to_a
  end

  def state_options
    %w(disabled enabled temporary).map { |m| [ I18n.t("cms.options.member_state.#{m}"), m ] }.to_a
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
    return if self.in_password.blank?

    errors.add :in_password, :password_short, count: 6 if self.in_password.length < 6
    errors.add :in_password, :password_alphabet_only if self.in_password =~ /[A-Z]/i && self.in_password !~ /[^A-Z]/i
    errors.add :in_password, :password_numeric_only if self.in_password =~ /[0-9]/ && self.in_password !~ /[^0-9]/
    errors.add :in_password, :password_include_email \
      if self.email.present? && self.in_password =~ /#{::Regexp.escape(self.email)}/
    errors.add :in_password, :password_include_name \
      if self.name.present? && self.in_password =~ /#{::Regexp.escape(self.name)}/
  end
end
