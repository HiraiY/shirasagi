class Gws::Reminder::Notification
  include SS::Document

  field :notify_at, type: DateTime
  field :delivered_at, type: DateTime

  field :state, type: String
  field :start_or_end, type: String, default: "start_at"
  field :interval, type: Integer
  field :interval_type, type: String
  field :base_time, type: String

  embedded_in :reminder, inverse_of: :notifications

  validates :notify_at, presence: true

  def interval_label
    label = []
    label << I18n.t("gws/reminder.options.base_time")[base_time.to_sym] if base_time
    if interval_type != "today"
      label << [
        I18n.t("gws/reminder.options.start_or_end")[start_or_end.to_sym],
        interval.to_s,
        I18n.t("gws/reminder.options.interval_type")[interval_type.to_sym]
      ].join
    end
    label.join(" ")
  end
end
