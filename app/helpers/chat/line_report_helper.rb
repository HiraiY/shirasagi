module Chat::LineReportHelper

  def link_to_monthly(date)
    @year  = date.year
    @month = date.month
    link_to "#{@year}年#{@month}月", chat_line_report_path(year: @year, month: @month)
  end
end
