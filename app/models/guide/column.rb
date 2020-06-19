class Guide::Column
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "guide_procedures"

  seqid :id
  field :name, type: String
  field :question, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :question, :order
  validates :name, presence: true, length: { maximum: 40 }
  validates :question, presence: true

  default_scope -> { order_by(order: 1, name: 1) }

  class << self
    def search(params = {})
      criteria = self.all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end
end
