class Chat::LineReportController < ApplicationController
  include Cms::BaseFilter
  helper Chat::LineReportHelper

  navi_view "cms/node/main/navi"

  before_action :set_year_month

  def index
    @record_phrases = Chat::LineBot::RecordPhrase.site(@cur_site).where(node_id: @cur_node.id).order_by(frequency: "DESC")
    @exists_phrases = Chat::LineBot::ExistsPhrase.site(@cur_site).where(node_id: @cur_node.id).order_by(frequency: "DESC")
    @sessions = Chat::LineBot::Session.site(@cur_site).where(node_id: @cur_node.id)
    @used_times = Chat::LineBot::UsedTime.site(@cur_site).where(node_id: @cur_node.id)

    year = params[:year]
    month = params[:month]

    if year.present? && month.present?
      @year = year.to_i
      @month = month.to_i
    end

    @current_month_date = Date.new(@year, @month, 1)
    @current_month_end_date = @current_month_date.end_of_month

    raise '404' if @current_month_date > Date.today.beginning_of_month
  end

  private

  def set_crumbs
    @crumbs << [I18n.t('chat.line_bot.line_report'), action: :index]
  end

  def set_year_month
    if @year.blank? || @month.blank?
      @year  = Time.zone.today.year.to_i
      @month = Time.zone.today.month.to_i
    end
  end
end
