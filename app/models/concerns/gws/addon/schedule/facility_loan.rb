module Gws::Addon::Schedule::FacilityLoan
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :loaned_facilities, class_name: "Gws::Facility::Item"

    field :return_item_at, type: DateTime

    validate :validate_loaned_facilities, if: ->{ facilities.present? }

    scope :loaned_facility, ->(item) { where loaned_facility_ids: item.id }
    scope :on_loan, ->(item = nil) do
      time = Time.zone.now

      cond = []
      cond << { :return_item_at.exists => false }
      cond << { "start_at" => { "$lte" => time } }

      if item
        cond << { loaned_facility_ids: item.id }
      else
        cond << { :loaned_facility_ids.exists => true }
      end

      self.and(cond)
    end
  end

  def loan_state
    return "" if loaned_facilities.blank?
    return "returned" if return_item_at.present?

    time = Time.zone.now
    if time < start_at
      return ""
    elsif time >= start_at && time <= end_at
      return "on_loan"
    else
      return "overdue"
    end
  end

  def loan_state_options
    I18n.t("gws/facility.options.loan_state").map { |k, v| [v, k] }
  end

  def approval_state_label
    approval_state.present? ? label(:approval_state) : ""
  end

  private

  def validate_loaned_facilities
    if @in_reset_approval == "approve" && loaned_facilities.present?
      errors.add :base, I18n.t("gws/schedule.errors.on_loan_faciliy")
      return
    end

    ids = []
    facilities.each do |facility|
      next if facility.loan_state != "enabled"

      if facility.approval_check_state == "enabled"
        if approval_state == "approve"
          ids << facility.id
        end
      else
        ids << facility.id
      end
    end
    self.loaned_facility_ids = ids
  end
end
