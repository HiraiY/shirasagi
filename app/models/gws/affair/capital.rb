class Gws::Affair::Capital
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::GroupPermission
  include Gws::SitePermission
  include Gws::Addon::Import::Affair::Capital

  set_permission_name 'gws_affair_capitals'

  seqid :id
  field :no, type: String
  field :name, type: String
  field :business_code, type: String
  field :details, type: String
  field :order, type: Integer, default: 0
  field :remark, type: String

  embeds_ids :capital_users, class_name: "Gws::User"

  permit_params :no, :name, :business_code, :details, :order, :remark
  permit_params capital_user_ids: []

  validates :no, presence: true, length: { maximum: 20 }
  validates :name, presence: true, length: { maximum: 80 }

  scope :site, ->(site) { self.in(group_ids: Gws::Group.site(site).pluck(:id)) }

  class << self
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :no, :name, :remark
      end
      criteria
    end
  end
end
