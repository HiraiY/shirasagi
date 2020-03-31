class Chat::LineReportController < ApplicationController
  include Cms::BaseFilter
  navi_view "cms/node/main/navi"

  def index
    @items = Chat::LineBot::Phrase.site(@cur_site).where(node_id: @cur_node.id).order_by(frequency: "DESC")
    @intents = Chat::Intent.site(@cur_site).where(node_id: @cur_node.id).order_by(frequency: "DESC")
    @users = Chat::LineBot::Session.site(@cur_site).where(node_id: @cur_node.id)
    @used_times = Chat::LineBot::UsedTime.site(@cur_site).where(node_id: @cur_node.id)
  end

  private

  def set_crumbs
    @crumbs << [I18n.t('chat.line_bot.line_report'), action: :index]
  end

  def cond
    { site_id: @cur_site.id }
  end
end
