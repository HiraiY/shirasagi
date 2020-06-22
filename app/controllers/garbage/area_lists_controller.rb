class Garbage::AreaListsController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Garbage::Node::Area

  navi_view "garbage/area_lists/nav"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def set_task
    @task = Cms::Task.find_or_create_by name: task_name, site_id: @cur_site.id, node_id: @cur_node.id
  end

  def task_name
    "garbage:import_node_areas"
  end

  def send_csv(items)
    require "csv"

    csv = CSV.generate do |data|
      headers = [
        t('garbage.area_name'),
        t('garbage.center')
      ]
      items.first.garbage_type.each do |type|
        headers << type[:field]
      end
      headers << @model.t(:filename)
      data << headers

      items.each do |item|
        row = []
        row << item.name
        row << item.center
        items.first.garbage_type.each do |type|
          row << type[:value]
        end
        row << item.basename
        data << row
      end
    end

    send_data csv.encode("SJIS", invalid: :replace, undef: :replace),
              filename: "area_days.csv"
  end

  public

  def download
    send_csv @cur_node.children.map(&:becomes_with_route)
  end

  def import
    raise "403" unless @model.allowed?(:import, @cur_user, site: @cur_site, node: @cur_node, owned: true)

    set_task

    if request.get?
      respond_to do |format|
        format.html { render }
        format.json { render json: @task.to_json(methods: :head_logs) }
      end
      return
    end

    @item = @model.new

    begin
      file = params[:item].try(:[], :file)
      if file.nil? || ::File.extname(file.original_filename) != ".csv"
        raise I18n.t("facility.import.invalid_file")
      end
      if !Garbage::Node::AreaImporter.valid_csv?(file)
        raise I18n.t("errors.messages.malformed_csv")
      end

      # save csv to use in job
      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.model = "garbage/area"
      ss_file.save

      # call job
      Garbage::Area::ImportJob.bind(site_id: @cur_site, node_id: @cur_node, user_id: @cur_user).perform_later(ss_file.id)
    rescue => e
      @item.errors.add :base, e.to_s
    end

    if @item.errors.present?
      render
    else
      redirect_to({ action: :import }, { notice: I18n.t("ss.notice.started_import") })
    end
  end
end