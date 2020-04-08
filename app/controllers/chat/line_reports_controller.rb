class Chat::LineReportsController < ApplicationController
  include Cms::BaseFilter
  helper Chat::LineReportsHelper

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

  def download_record_phrases
    @models = Chat::LineBot::RecordPhrase.site(@cur_site).where(node_id: @cur_node.id).order_by(frequency: "DESC")
    send_csv_record_phrases @models
    end

  def download_exists_phrases
    @models = Chat::LineBot::ExistsPhrase.site(@cur_site).where(node_id: @cur_node.id).order_by(frequency: "DESC")
    send_csv_exists_phrases @models
  end

  def download_sessions
    @session_counts = params[:session_counts]
    @dates = params[:dates]
    @current_date = params[:current_date]
    send_csv_sessions(@session_counts, @dates)
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

  def send_csv_record_phrases(items)
    headers = %w(name frequency)
    csv = CSV.generate do |data|
      data << headers
      items.each do |item|
        row = []
        row << item.name
        row << item.frequency
        data << row
      end
    end

    send_data csv.encode("SJIS", invalid: :replace, undef: :replace),
              filename: "record_phrase#{Time.zone.now.to_i}.csv"
  end

  def send_csv_exists_phrases(items)
    headers = %w(name frequency confirm_yes confirm_no reply_count reply_rate)
    csv = CSV.generate do |data|
      data << headers
      items.each do |item|
        row = []
        row << item.name
        row << item.frequency
        row << item.confirm_yes
        row << item.confirm_no
        row << item.confirm_yes + item.confirm_no
        row << "#{((item.confirm_yes + item.confirm_no).fdiv(item.frequency) * 100).floor}%"
        data << row
      end
    end

    send_data csv.encode("SJIS", invalid: :replace, undef: :replace),
              filename: "exists_phrase#{Time.zone.now.to_i}.csv"
  end

  def send_csv_sessions(items, dates)
    headers = %w(date count)
    csv = CSV.generate do |data|
      data << headers
      items.zip(dates).each do |item, date|
        row = []
        row << date
        row << item
        data << row
      end
      row = []
      row << "total"
      row << items.map(&:to_i).sum
      data << row
    end

    send_data csv.encode("SJIS", invalid: :replace, undef: :replace),
              filename: "session_counts_#{@current_date}_#{Time.zone.now.to_i}.csv"
  end
end
