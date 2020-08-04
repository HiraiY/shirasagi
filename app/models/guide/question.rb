class Guide::Question
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  # include Guide::Addon::Genre
  include Cms::Addon::GroupPermission

  set_permission_name "guide_procedures"

  seqid :id
  field :name, type: String
  field :question, type: String
  field :select_options, type: SS::Extensions::Lines
  field :order, type: Integer, default: 0

  embeds_ids :columns, class_name: "Guide::Column"

  permit_params :name, :question, :select_options, :order
  validates :name, presence: true, length: { maximum: 40 }
  validates :question, presence: true, uniqueness: { scope: :site_id }

  default_scope -> { order_by(order: 1, name: 1) }

  before_save :create_guide_columns
  after_destroy :destroy_guide_columns

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

  private

  def create_guide_columns
    columns = select_options.presence ||
              [I18n.t('guide.links.applicable'), I18n.t('guide.links.not_applicable')]
    columns.collect! do |column|
      column.split(/[#{%w(, 、 ，).join}]/).map(&:strip)
    end
    self.columns.site(site).
      in(select_options_id: self.columns.pluck(:select_options_id) - columns.collect(&:first)).
      destroy
    self.column_ids = columns.collect.with_index do |column, index|
      item = Guide::Column.find_or_initialize_by(site_id: site.id, question_id: id, select_options_id: column.first)
      item.name = column.last
      item.order = index
      item.save!
      item.id
    end
  end

  def destroy_guide_columns
    columns.destroy
  end
end
