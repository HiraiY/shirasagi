class Gws::Affair::Enumerator::Base < Enumerator
  def bom
    return '' if @params.encoding == 'Shift_JIS'
    "\uFEFF"
  end

  def encode(str)
    return '' if str.blank?

    str = str.encode('CP932', invalid: :replace, undef: :replace) if @params.encoding == 'Shift_JIS'
    str
  end

  def format_minute(minute)
    (minute.to_i > 0) ? "#{minute / 60}:#{format("%02d", (minute % 60))}" : ""
  end
end
