class Chat::LineReportController < ApplicationController
  include Cms::BaseFilter
  navi_view "cms/node/main/navi"

  def index
    @items = Chat::LineBot::Phrase.site(@cur_site).order_by(frequency: "DESC")
    @intents = Chat::Intent.site(@cur_site)
    @users = Chat::LineBot::Session
  end

  private

  def set_crumbs
    @crumbs << [I18n.t('chat.line_bot.line_report'), action: :index]
  end

  def cond
    { site_id: @cur_site.id }
  end
end
