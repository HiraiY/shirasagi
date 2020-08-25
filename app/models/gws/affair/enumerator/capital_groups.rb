class Gws::Affair::Enumerator::CapitalGroups < Gws::Affair::Enumerator::Base
  def initialize(prefs, title, capitals, groups, descendants, params)
    @prefs = prefs
    @title = title
    @capitals = capitals
    @descendants = descendants
    @groups = groups
    @params = params

    @total = !(@params[:total] == false)

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
    @groups.each do |group|
      terms << group.trailing_name
    end
    terms << I18n.t("gws/affair.labels.overtime.capitals.total") if @total
    terms
  end

  def enum_row(yielder, capital)
    line = []
    line << capital.name

    total = 0
    @groups.each do |group|
      group_ids = [group.id] + @descendants[group.id].to_a.map(&:id)
      minute = group_ids.map { |id| @prefs.dig(id, capital.id).to_i }.sum
      total += minute
      line << format_minute(minute)
    end
    line << format_minute(total) if @total

    yielder << encode(line.to_csv)
  end

  def enum_total(yielder)
    line = []
    line << I18n.t("gws/affair.labels.overtime.capitals.total_capitals")

    total = 0
    @groups.each do |group|
      group_ids = [group.id] + @descendants[group.id].to_a.map(&:id)
      minute = group_ids.map { |id| @prefs.dig(id, "total").to_i }.sum
      total += minute
      line << format_minute(minute)
    end
    line << format_minute(total) if @total

    yielder << encode(line.to_csv)
  end
end
