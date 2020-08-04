class Guide::ProceduresController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Guide::Procedure
  navi_view "cms/node/main/navi"

  private

  def set_crumbs
    @crumbs << [t("guide.procedure"), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end

  public

  def download
    csv = @model.allow(:read, @cur_user, site: @cur_site, node: @cur_node).
        to_csv(@cur_site).encode("SJIS", invalid: :replace, undef: :replace)
    filename = @model.to_s.tableize.gsub(/\//, "_")
    send_data csv, filename: "#{filename}_#{Time.zone.now.to_i}.csv"
  end

  def import
    @item = @model.new
    return if request.get?

    begin
      file = params[:item].try(:[], :in_file)
      raise I18n.t("errors.messages.invalid_csv") if file.nil? || ::File.extname(file.original_filename) != ".csv"
      CSV.read(file.path, headers: true, encoding: 'SJIS:UTF-8')

      # save csv to use in job
      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.model = "guide/procedure"
      ss_file.save

      # call job
      Guide::Procedure::ImportJob.bind(site_id: @cur_site).perform_later(ss_file.id)
      flash.now[:notice] = I18n.t("ss.notice.started_import")
    rescue => e
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      @item.errors.add :base, e.to_s
    end
  end
end
