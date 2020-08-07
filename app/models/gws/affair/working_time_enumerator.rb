class Gws::Affair::WorkingTimeEnumerator < Enumerator

  def initialize(site, users, time_cards, params)
    @cur_site = site
    @users = users
    @time_cards = time_cards.dup
    @params = params

    super() do |y|
      y << bom + encode(headers.to_csv)
      @users.each do |user|
        time_card = @time_cards[user.id]
        line = []
        line << user.long_name
        line << user.organization_uid
        line << time_card.try(:total_working_minute_label)
        y << encode(line.to_csv)
      end
    end
  end

  def headers
    terms = []
    terms << Gws::User.t(:name)
    terms << Gws::User.t(:organization_uid)
    terms << I18n.t("gws/attendance.views.total_working_minute")
    terms
  end

  private

  def bom
    return '' if @params.encoding == 'Shift_JIS'
    "\uFEFF"
  end

  def encode(str)
    return '' if str.blank?

    str = str.encode('CP932', invalid: :replace, undef: :replace) if @params.encoding == 'Shift_JIS'
    str
  end
end
