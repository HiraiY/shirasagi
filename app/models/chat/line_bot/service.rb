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
              if phrase(event).suggest.present?
                client.reply_message(event["replyToken"], suggests(event))
              elsif phrase(event).link.present?
                client.reply_message(event["replyToken"], links(event))
              elsif phrase(event).response.present?
                client.reply_message(event["replyToken"], res(event))
              end
            end
          rescue
            answer(event)
          end
        when Line::Bot::Event::MessageType::Location
          client.reply_message(event["replyToken"], carousel(event))
        end
      end
    end
  end

  private

  def phrase(event)
    Chat::Intent.site(@cur_site).where(node_id: @cur_node.id).find_by({phrase: event.message['text']})
  end

  def suggest_text(event, templates)
    if templates.empty?
      if phrase(event).suggest.present? && phrase(event).response.present?
        phrase(event).response.gsub(%r{</?[^>]+?>}, "")
      else
        @cur_node.response_template.gsub(%r{</?[^>]+?>}, "")
      end
    else
      "選択肢#{templates.length + 1}"
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
    templates << site_search(event) if phrase(event).site_search == "enabled"
    templates << question if phrase(event).question == "enabled"
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
      "選択肢#{templates.length + 1}"
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
    templates << site_search(event) if phrase(event).site_search == "enabled"
    templates << question if phrase(event).question == "enabled"
    templates
  end

  def res(event)
    template =
      {
        "type": "text",
        "text": phrase(event).response.gsub(%r{</?[^>]+?>}, "")
      }
    template << site_search(event) if phrase(event).site_search == "enabled"
    template << question if phrase(event).question == "enabled"
    template
  end

  def question
    {
      "type": "template",
      "altText": "this is a confirm template",
      "template": {
        "type": "confirm",
        "text": @cur_node.question.gsub(%r{</?[^>]+?>}, ""),
        "actions": [
          {
            "type": "message",
            "label": "Yes",
            "text": "yes"
          },
          {
            "type": "message",
            "label": "No",
            "text": "no"
          }
        ]
      }
    }
  end

  def answer(event)
    begin
      if event.message["text"].eql?("yes")
        client.reply_message(event["replyToken"], {
          "type": "text",
          "text": @cur_node.chat_success.gsub(%r{</?[^>]+?>}, "")
        })
      elsif event.message["text"].eql?("no")
        client.reply_message(event["replyToken"], {
          "type": "text",
          "text": @cur_node.chat_retry.gsub(%r{</?[^>]+?>}, "")
        })
      elsif event.message["text"].eql?("近くの施設を探す")
        set_location(event)
      end
    rescue
      template = []
      template << no_match << site_search(event)
      client.reply_message(event["replyToken"], template)
    end
  end

  def site_search(event)
    uri = URI.parse(@cur_node.url)
    uri.query = {s: {keyword: event.message["text"]}}.to_query
    url = uri.try(:to_s)
    template = {
      "type": "template",
      "altText": "this is a buttons template",
      "template": {
        "type": "buttons",
        "text": "サイト内検索結果を開く",
        "actions": [
          {
            "type": "uri",
            "label": "サイト内検索結果へ移動",
            "uri": "https://" + @cur_site.domains[1] + url
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

  def set_location(event)
    client.reply_message(event["replyToken"], {
      "type": "template",
      "altText": "位置検索中",
      "template": {
        "type": "buttons",
        "text": "現在の位置を送信しますか？",
        "actions": [
          {
            "type": "uri",
            "label": "位置を送る",
            "uri": "line://nv/location"
          }
        ]
      }
    })
  end

  def carousel(event)
    @lat = event["message"]["latitude"]
    @lng = event["message"]["longitude"]
    @radius = 3
    @lat = @lat.to_f
    @lng = @lng.to_f

    if @lat >= -90 && @lat <= 90 && @lng >= -180 && @lng <= 180
      @loc = [@lng, @lat]
    end

    facilities = Facility::Map.site(@cur_site).where(
      map_points: {
        "$elemMatch" => {
          "loc" => {
            "$geoWithin" => { "$centerSphere" => [ @loc, @radius / EARTH_RADIUS_KM ] }
          }
        }
      }
    ).to_a

    if facilities.empty?
      client.reply_message(event['replyToken'], {
        "type": "text",
        "text": "近くに施設はありませんでした。"
      })
    else
      @markers = facilities.map do |item|
        points = item.map_points.map do |point|
          point[:facility_url] = item.url
          point[:distance] = ::Geocoder::Calculations.distance_between(@loc, [point["loc"]["lng"], point["loc"]["lat"]], units: :km) rescue 0.0
          point
        end
        points
      end.flatten

      @markers = @markers.sort_by { |point| point[:distance] }
      @markers = @markers[0..9]

      columns = []
      domain = @cur_site.domains[1]
      @markers.each do |map|
        item = Facility::Node::Page.site(@cur_site).and_public.in_path(map[:facility_url]).first
        map_lat = map[:loc]["lat"]
        map_lng = map[:loc]["lng"]
        if map[:distance] > 1.0
          distance = "約#{map[:distance].round(1)}km"
        else
          distance = "約#{(map[:distance] * 1000).round}m"
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
                "label": "地図",
                "uri": "https://www.google.com/maps/search/?api=1&query=#{map_lat},#{map_lng}"
              },
              {
                "type": "uri",
                "label": "詳細情報",
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
