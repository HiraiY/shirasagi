module SS::User::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Cms::Reference::Role
  include Sys::Reference::Role

  attr_accessor :in_password

  included do
    store_in collection: "ss_users"
    index({ email: 1 }, { unique: true })

    seqid :id
    field :name, type: String
    field :uid, type: String
    field :email, type: String, metadata: { form: :email }
    field :password, type: String
    field :type, type: String
    field :last_loggedin, type: DateTime

    embeds_ids :groups, class_name: "SS::Group"

    permit_params :name, :email, :password, :in_password, :type, group_ids: []

    validates :name, presence: true, length: { maximum: 40 }
    validates :email, uniqueness: true, presence: true, email: true, length: { maximum: 80 }
    validates :password, presence: true

    before_validation :encrypt_password, if: ->{ in_password.present? }

    public
      def type_options
        [%w(SNSユーザー sns), %w(LDAPユーザー ldap)]
      end
  end

  module ClassMethods
    public
      def search(params)
        criteria = self.where({})
        return criteria if params.blank?

        if params[:name].present?
          criteria = criteria.search_text params[:name]
        end
        if params[:keyword].present?
          criteria = criteria.keyword_in params[:keyword], :name, :email
        end
        criteria
      end
  end

  def encrypt_password
    self.password = SS::Crypt.crypt(in_password)
  end

  def uid_to_disp
    if uid.present?
      uid
    else
      email.split('@')[0]
    end
  end

  # detail, descriptive name
  def long_name
    "#{name}(#{uid_to_disp})"
  end
end
