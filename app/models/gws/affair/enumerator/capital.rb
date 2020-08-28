class Gws::Affair::Enumerator::Capital < Gws::Affair::Enumerator::Base
  def initialize(prefs, title, capitals, dates, params)
    @prefs = prefs
    @title = title
    @capitals = capitals
    @dates = dates
    @params = params

    super() do |y|
      y << bom + encode([@title.to_s].to_csv)
      y << encode(headers.to_csv)
      @capitals.each do |capital|
        enum_row(y, capital)
      end
      enum_total(y)
    end
  end

  def headers
    terms = []
    terms << I18n.t("gws/affair.labels.overtime.capitals.capital")
    @dates.each do |date|
      terms << "#{date.month}#{I18n.t("datetime.prompts.month")}"
    end
    terms << I18n.t("gws/affair.labels.overtime.capitals.total")
    terms
  end

  def enum_row(yielder, capital)
    line = []
    line << capital.name

    total = 0
    @dates.each do |date|
      minute = @prefs.dig(date.year, date.month, capital.id).to_i
      total += minute
      line << format_minute(minute)
    end
    line << format_minute(total)

    yielder << encode(line.to_csv)
  end

  def enum_total(yielder)
    line = []
    line << I18n.t("gws/affair.labels.overtime.capitals.total_capitals")

    total = 0
    @dates.each do |date|
      minute = @prefs.dig(date.year, date.month, "total").to_i
      total += minute
      line << format_minute(minute)
    end
    line << format_minute(total)

    yielder << encode(line.to_csv)
  end
end
