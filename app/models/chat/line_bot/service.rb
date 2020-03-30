class Chat::LineBot::Service
  include ActiveModel::Model
  include ActiveModel::Validations

  require "line/bot"

  EARTH_RADIUS_KM = 6378.137

  attr_accessor :cur_site, :cur_node, :request

  validate do
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    body = request.body.read
    unless client.validate_signature(body, signature)
      errors.add(:request, :signature_mismatched)
    end
  end

  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = @cur_site.line_channel_secret
      config.channel_token = @cur_site.line_channel_access_token
    end
  end

  def call
    body = request.body.read
    events = client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          begin
            if phrase(event).present?
              add_intent_frequency = phrase(event)
              add_intent_frequency.frequency += 1
              add_intent_frequency.save
              if phrase(event).suggest.present?
                client.reply_message(event["replyToken"], suggests(event))
              elsif phrase(event).link.present?
                client.reply_message(event["replyToken"], links(event))
              elsif phrase(event).response.present?
                client.reply_message(event["replyToken"], res(event))
              end
            end
          rescue
            begin
              answer(event) if phrase(event).present?
            rescue
              record_phrase(event)
            end
            answer(event)
          end
        when Line::Bot::Event::MessageType::Location
          client.reply_message(event["replyToken"], show_facilities(event))
        end
      when Line::Bot::Event::Postback
        if event['postback']['data'].split(',')[0] == 'yes'
          add_confirm_yes = postback_intent(event)
          add_confirm_yes.confirm_yes += 1
          add_confirm_yes.save
          client.reply_message(event["replyToken"], {
            "type": "text",
            "text": @cur_node.chat_success.gsub(%r{</?[^>]+?>}, "")
          })
        elsif event['postback']['data'].split(',')[0] == 'no'
          add_confirm_no = postback_intent(event)
          add_confirm_no.confirm_no += 1
          add_confirm_no.save
          client.reply_message(event["replyToken"], {
            "type": "text",
            "text": @cur_node.chat_retry.gsub(%r{</?[^>]+?>}, "")
          })
        end
      end
    end
  end

  private

  def phrase(event)
    Chat::Intent.site(@cur_site).where(node_id: @cur_node.id).find_by(phrase: event.message['text'])
  end

  def postback_intent(event)
    Chat::Intent.find_by(phrase: event['postback']['data'].split(',')[1].strip)
  end

  def record_phrase(event)
    begin
      phrase = Chat::LineBot::Phrase.site(@cur_site).find_by(name: event.message["text"])
      phrase.frequency += 1
      phrase.save
    rescue
      phrase = Chat::LineBot::Phrase.create(site_id: @cur_site.id, name: event.message["text"])
      phrase.frequency += 1
      phrase.save
    end
  end

  def suggest_text(event, templates)
    if templates.empty?
      if phrase(event).suggest.present? && phrase(event).response.present?
        phrase(event).response.gsub(%r{</?[^>]+?>}, "")
      else
        @cur_node.response_template.gsub(%r{</?[^>]+?>}, "")
      end
    else
      I18n.t("chat.line_bot.choices") + "#{templates.length + 1}"
    end
  end

  def suggests(event)
    suggests = phrase(event).suggest
    actions = suggests.each_slice(4).to_a
    action_templates = []
    suggest_templates = []
    actions.each do |action|
      action.each do |suggest|
        suggest_templates << {
          "type": "message",
          "label": suggest,
          "text": suggest
        }
      end
      action_templates << suggest_templates
      suggest_templates = []
    end

    templates = []
    action_templates.each do |action|
      template =
        {
          "type": "template",
          "altText": "this is a buttons template",
          "template": {
            "type": "buttons",
            "actions": action,
            "text": suggest_text(event, templates)
          }
        }
      templates << template
    end
    templates << site_search(event) if phrase(event).site_search == "enabled" && site_search?
    templates << question(event) if phrase(event).question == "enabled" && question?
    templates
  end

  def link_text(event, templates)
    if templates.empty?
      if phrase(event).response.scan(/<p(?: .+?)?>.*?<\/p>/).present?
        phrase(event).response.scan(/<p(?: .+?)?>.*?<\/p>/).join("").gsub(%r{</?[^>]+?>}, "")
      else
        @cur_node.response_template.gsub(%r{</?[^>]+?>}, "")
      end
    else
      I18n.t("chat.line_bot.choices") + "#{templates.length + 1}"
    end
  end

  def links(event)
    labels = phrase(event).response.scan(/<a(?: .+?)?>.*?<\/a>/)
    actions = labels.each_slice(4).to_a
    links = phrase(event).link.each_slice(4).to_a
    action_templates = []
    link_templates = []
    actions.zip(links).each do |action, link|
      action.zip(link).each do |label, url|
        link_templates << {
          "type": "uri",
          "label": label.gsub(%r{</?[^>]+?>}, ""),
          "uri": url
        }
      end
      action_templates << link_templates
      link_templates = []
    end

    templates = []
    action_templates.each do |action|
      template =
        {
          "type": "template",
          "altText": "this is a buttons template",
          "template": {
            "type": "buttons",
            "actions": action,
            "text": link_text(event, templates)
          }
        }
      templates << template
    end
    templates << site_search(event) if phrase(event).site_search == "enabled" && site_search?
    templates << question(event) if phrase(event).question == "enabled" && question?
    templates
  end

  def res(event)
    template =
      {
        "type": "text",
        "text": phrase(event).response.gsub(%r{</?[^>]+?>}, "")
      }
    template << site_search(event) if phrase(event).site_search == "enabled" && site_search?
    template << question(event) if phrase(event).question == "enabled" && question?
    template
  end

  def question?
    @cur_node.question.present? && @cur_node.chat_success.present? && @cur_node.chat_retry.present?
  end

  def question(event)
    {
      "type": "template",
      "altText": "this is a confirm template",
      "template": {
        "type": "confirm",
        "text": @cur_node.question.gsub(%r{</?[^>]+?>}, ""),
        "actions": [
          {
            "type": "postback",
            "label": I18n.t("chat.line_bot.success"),
            "data": "yes, #{event.message['text']}"
          },
          {
            "type": "postback",
            "label": I18n.t("chat.line_bot.retry"),
            "data": "no, #{event.message['text']}"
          }
        ]
      }
    }
  end

  def answer(event)
    if event.message["text"].eql?(I18n.t("chat.line_bot.search_location"))
      send_location(event)
    else
      template = []
      template << no_match
      template << site_search(event) if site_search?
      client.reply_message(event["replyToken"], template)
    end
  end

  def site_search?
    Cms::Node::SiteSearch.site(@cur_site).and_public.first.present?
  end

  def site_search(event)
    site_search_node = Cms::Node::SiteSearch.site(@cur_site).first
    uri = URI.parse(site_search_node.url)
    uri.query = {s: {keyword: event.message["text"]}}.to_query
    url = uri.try(:to_s)
    template = {
      "type": "template",
      "altText": "this is a buttons template",
      "template": {
        "type": "buttons",
        "text": I18n.t("chat.line_bot.site_search"),
        "actions": [
          {
            "type": "uri",
            "label": I18n.t("chat.line_bot.search_results"),
            "uri": "https://" + @cur_site.domains.first + url
          }
        ]
      }
    }
    template
  end

  def no_match
    {
      "type": "text",
      "text": @cur_node.exception_text.gsub(%r{</?[^>]+?>}, "")
    }
  end

  def send_location(event)
    client.reply_message(event["replyToken"], {
      "type": "template",
      "altText": "searching location",
      "template": {
        "type": "buttons",
        "text": I18n.t("chat.line_bot.send_location"),
        "actions": [
          {
            "type": "uri",
            "label": I18n.t("chat.line_bot.set_location"),
            "uri": "line://nv/location"
          }
        ]
      }
    })
  end

  def set_loc(event)
    @lat = event["message"]["latitude"]
    @lng = event["message"]["longitude"]
    @radius = 3
    @lat = @lat.to_f
    @lng = @lng.to_f

    if @lat >= -90 && @lat <= 90 && @lng >= -180 && @lng <= 180
      @loc = [@lng, @lat]
    end
  end

  def search_facilities(event)
    set_loc(event)
    @facilities = Facility::Map.site(@cur_site).where(
      map_points: {
        "$elemMatch" => {
          "loc" => {
            "$geoWithin" => { "$centerSphere" => [ @loc, @radius / EARTH_RADIUS_KM ] }
          }
        }
      }
    ).to_a

    @markers = @facilities.map do |item|
      points = item.map_points.map do |point|
        point[:facility_url] = item.url
        point[:distance] = ::Geocoder::Calculations.distance_between(@loc, [point[:loc][0], point[:loc][1]], units: :km) rescue 0.0
        point[:state] = Facility::Node::Page.site(@cur_site).in_path(point[:facility_url]).first.state
        point
      end
      points
    end.flatten

    @markers = @markers.delete_if do |item|
      item[:state] == "closed"
    end
    @markers = @markers.sort_by { |point| point[:distance] }
    @markers = @markers[0..9]
  end

  def show_facilities(event)
    search_facilities(event)
    if @facilities.empty?
      client.reply_message(event['replyToken'], {
        "type": "text",
        "text": I18n.t("chat.line_bot.no_facility")
      })
    else
      columns = []
      domain = @cur_site.domains.first
      @markers.each do |map|
        item = Facility::Node::Page.site(@cur_site).in_path(map[:facility_url]).first
        map_lat = map[:loc][1]
        map_lng = map[:loc][0]
        if map[:distance] > 1.0
          distance = I18n.t("chat.line_bot.about") + "#{map[:distance].round(1)}km"
        else
          distance = I18n.t("chat.line_bot.about") + "#{(map[:distance] * 1000).round}m"
        end
        column =
          {
            "title": item.name,
            "text": "#{item.address}\n #{distance}",
            "defaultAction": {
              "type": "uri",
              "label": "View detail",
              "uri": "https://" + domain + item.url
            },
            "actions": [
              {
                "type": "uri",
                "label": I18n.t("chat.line_bot.map"),
                "uri": "https://www.google.com/maps/search/?api=1&query=#{map_lat},#{map_lng}"
              },
              {
                "type": "uri",
                "label": I18n.t("chat.line_bot.details"),
                "uri": "https://" + domain + item.url
              }
            ]
          }
        columns << column
      end

      template = {
        "type": "template",
        "altText": "this is a carousel template",
        "template": {
          "type": "carousel",
          "columns": columns,
          "imageAspectRatio": "rectangle",
          "imageSize": "cover"
        }
      }
      template
    end
  end
end
