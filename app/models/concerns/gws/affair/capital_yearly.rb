module Gws::Affair::CapitalYearly
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :year_code, type: String
    field :year_name, type: String

    belongs_to :year, class_name: 'Gws::Affair::CapitalYear'

    permit_params :year_id

    validates :year_id, presence: true
    validates :year_code, presence: true
    validates :year_name, presence: true

    before_validation :set_year_name, if: -> { year_id.present? && year_id_changed? }
  end

  private

  def set_year_name
    if year_id.present?
      item = Gws::Affair::CapitalYear.where(site_id: site_id, id: year_id).first
      self.year_code = item ? item.code : nil
      self.year_name = item ? item.name : nil
    else
      @cur_year = Gws::Affair::CapitalYear.site(@cur_site).first
    end
  end
end
