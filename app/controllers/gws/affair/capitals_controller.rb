class Gws::Affair::CapitalsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair::Capital

  navi_view "gws/affair/main/navi"
  menu_view "gws/affair/main/menu"

  before_action :set_year

  private

  def set_crumbs
    @cur_year = Gws::Affair::CapitalYear.site(@cur_site).find(params[:year])
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t("mongoid.models.gws/affair/capital_year"), gws_affair_capital_years_path]
    @crumbs << ["#{@cur_year.name} " + t('modules.gws/affair/capital'), gws_affair_capitals_path]
  end

  def set_year
    @cur_year ||= Gws::Affair::CapitalYear.site(@cur_site).find(params[:year])
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, year_id: @cur_year.id }
  end

  def set_items
    @items = @cur_year.yearly_capitals.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      order_by(id: 1)
  end

  public

  def index
    @items = @cur_year.yearly_capitals.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def download
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    set_items
    csv = @items.to_csv
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "gws_affair_capitals_#{Time.zone.now.to_i}.csv"
  end

  def import
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    return if request.get?
    @item = @model.new get_params
    @item.cur_site = @cur_site
    @item.cur_user = @cur_user
    result = @item.import
    flash.now[:notice] = t("ss.notice.saved") if !result && @item.imported > 0
    render_create result, location: { action: :index }, render: { file: :import }
  end
end
