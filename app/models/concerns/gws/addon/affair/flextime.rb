module Gws::Addon::Affair::Flextime
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :flextime_state, type: String, default: "disabled"
    permit_params :flextime_state
    has_many :time_card_notices, class_name: 'Gws::Affair::TimeCardNotice', dependent: :destroy, inverse_of: :duty_calendar
  end

  def flextime?
    flextime_state == "enabled"
  end

  def flextime_state_options
    [
      [I18n.t("ss.options.state.enabled"), "enabled"],
      [I18n.t("ss.options.state.disabled"), "disabled"],
    ]
  end

  def notices(time_card)
    total_working_minute = time_card.total_working_minute
    messages = []

    time_card_notices.map do |notice|
      if total_working_minute >= (notice.threshold_hour * 60)
        messages << "就業時間合計が#{notice.threshold_hour}時間を超過しています。"
      end
    end
    messages
  end
end
