module Gws::Affair::Overtime::AggregateFilter
  extend ActiveSupport::Concern

  def set_time_cards
    @unlocked_time_cards = []
    date = Time.new(@year, @month, 1, 0, 0, 0).in_time_zone
    @users.each do |user|
      title = I18n.t(
          'gws/attendance.formats.time_card_full_name',
          user_name: user.name, month: I18n.l(date.to_date, format: :attendance_year_month)
      )
      time_card = Gws::Attendance::TimeCard.site(@cur_site).user(user).where(date: date).first
      if !time_card || !time_card.locked?
        @unlocked_time_cards << title
      end
    end
  end

  def set_download_params
    safe_params = params.require(:s).permit(:encoding)
    @download_params = OpenStruct.new(encoding: safe_params[:encoding])
  end
end
