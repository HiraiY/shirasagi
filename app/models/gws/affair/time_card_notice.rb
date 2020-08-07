class Gws::Affair::TimeCardNotice
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site

  seqid :id
  belongs_to :duty_calendar, class_name: "Gws::Affair::DutyCalendar", inverse_of: :time_card_notices
  validates :duty_calendar_id, presence: true

  field :notice_type, type: String
  field :period_type, type: String
  field :threshold_hour, type: Integer

  permit_params :notice_type
  permit_params :period_type
  permit_params :threshold_hour

  validates :notice_type, presence: true
  validates :period_type, presence: true
  validates :threshold_hour, presence: true

  def name
    "#{label(:notice_type)} #{label(:period_type)} #{threshold_hour} #{I18n.t("ss.time")}"
  end

  def notice_type_options
    I18n.t("gws/affair.options.notice_type").map { |k, v| [v, k] }
  end

  def period_type_options
    I18n.t("gws/affair.options.period_type").map { |k, v| [v, k] }
  end

  def allowed?(action, user, opts = {})
    true
  end

  class << self
    def allowed?(action, user, opts = {})
      true
    end

    def allow(action, user, opts = {})
      self.where({})
    end
  end
end
