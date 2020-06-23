class Garbage::Node::AreaImporter
  include Cms::CsvImportBase

  self.required_headers = [ ::Garbage::Node::Area.t(:filename) ]

  attr_reader :site, :node, :user

  def initialize(site, node, user)
    @site = site
    @node = node
    @user = user
  end

  def import(file, opts = {})
    @task = opts[:task]

    put_log("import start #{file.filename}")
    import_csv(file)
  end

  private

  def model
    ::Garbage::Node::Area
  end

  def put_log(message)
    if @task
      @task.log(message)
    else
      Rails.logger.info(message)
    end
  end

  def import_csv(file)
    table = CSV.read(file.path, headers: true, encoding: 'BOM|UTF-8')
    table.each_with_index do |row, i|
      begin
        name = update_row(row)
        put_log("update #{i + 1}: #{name}")
      rescue => e
        put_log("error  #{i + 1}: #{e}")
      end
    end
  end

  def update_row(row)
    filename = "#{node.filename}/#{row[model.t(:filename)].to_s.strip}"
    item = model.find_or_initialize_by filename: filename, site_id: site.id
    raise I18n.t('errors.messages.auth_error') unless item.allowed?(:import, user, site: site, node: node)
    item.cur_site = site
    set_page_attributes(row, item)
    raise I18n.t('errors.messages.auth_error') unless item.allowed?(:import, user, site: site, node: node)

    if item.save
      name = item.name
    else
      raise item.errors.full_messages.join(", ")
    end

    return name
  end

  def set_page_attributes(row, item)
    item.name   = row[I18n.t('garbage.area_name')].to_s.strip
    item.center = row[I18n.t('garbage.center')].to_s.strip
    row_last = row.index(model.t("filename"))
    garbage_type = []
    row.headers[2...row_last].zip(row[2...row_last]) do |key, value|
      hash = {field: key, value: value}
      garbage_type << hash
    end

    item.garbage_type = garbage_type
    set_page_categories(row, item)
    set_page_groups(row, item)

    item
  end

  def set_page_categories(row, item)
    @st_categories ||= node.becomes_with_route.st_categories.map{ |c| [c.name, c.id] }.to_h
    categories = row[model.t("category_ids")].to_s.strip.split("\n")
    item.category_ids = categories.map{ |c| @st_categories[c] }.compact
  end

  def set_page_groups(row, item)
    @groups ||= SS::Group.all.map{ |g| [g.name, g.id] }.to_h
    groups = row[model.t("groups")].to_s.strip.split("\n")
    item.group_ids = groups.map { |g| @groups[g] }.compact
  end
end
