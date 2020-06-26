module Garbage::Addon
  module Remark
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :remark_id, type: Integer
      field :attention, type: String

      permit_params :remark_id, :attention

      validates :remark_id, presence: true, :numericality => { greater_than_or_equal_to: 1 }
      validates :attention, presence: true
    end
  end
end