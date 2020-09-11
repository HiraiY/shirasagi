class Gws::Affair::CapitalYear
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::GroupPermission
  include Gws::SitePermission
  include Gws::Addon::History

  set_permission_name 'gws_affair_capital_years'

  seqid :id
  field :name, type: String
  field :code, type: String
  field :start_date, type: Date
  field :close_date, type: Date

  has_many :yearly_capitals, class_name: 'Gws::Affair::Capital', dependent: :destroy

  permit_params :code, :name, :start_date, :close_date

  validates :code, presence: true, uniqueness: { scope: :site_id }
  validates :name, presence: true, uniqueness: { scope: :site_id }
  validates :start_date, presence: true, datetime: true
  validates :close_date, presence: true, datetime: true

  default_scope -> { order_by start_date: -1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :code, :name
    end
    criteria
  }

  def name_with_code
    "#{name} (#{code})"
  end
end
