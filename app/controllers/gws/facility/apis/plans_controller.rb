class Gws::Facility::Apis::PlansController < ApplicationController
  include Gws::ApiFilter

  helper Gws::Schedule::PlanHelper

  model Gws::Schedule::Plan

  before_action :set_facility

  private

  def set_facility
    @facility = Gws::Facility::Item.site(@cur_site).find(params[:facility])
  end

  public

  def on_loan
    @items = Gws::Schedule::Plan.without_deleted.on_loan(@facility)
  end

  def return_item
    @item = Gws::Schedule::Plan.find(params[:id])
    @item.cur_site = @cur_site
    @item.return_item_at = Time.zone.now
    @item.update

    location = params[:redirect_to].present? ? CGI.unescapeHTML(params[:redirect_to]) : gws_facility_schedule_path
    redirect_to(location, { notice: I18n.t("ss.notice.returned") })
  end
end
