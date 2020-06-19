module Guide::ListHelper
  def default_procedure_loop_html
    ih = []
    ih << '<dl class="procedure item-#{id}">'
    ih << '  <dt>#{link}</dt>'
    ih << '  <dd>#{html}</dd>'
    ih << '</dl>'
    ih.join("\n").freeze
  end

  def default_procedure_loop_liquid
    ih = []
    ih << '{% for item in procedures %}'
    ih << '<dl class="procedure item-{{ item.id }}">'
    ih << '  <dt>'
    ih << '    {% if item.link_url %}'
    ih << '      <a href="{{ item.link_url }}">{{ item.name }}</a>'
    ih << '    {% else %}'
    ih << '      {{ item.name }}'
    ih << '    {% endif %}'
    ih << '  </dt>'
    ih << '  <dd>{{ item.procedure_location }}</dd>'
    ih << '</dl>'
    ih << '{% endfor %}'
    ih.join("\n").freeze
  end

  def render_procedure_list(&block)
    cur_item = @cur_part || @cur_node
    @items ||= @procedures
    if @items.blank? && cur_item.try(:no_items_display_state) == 'hide'
      return cur_item.substitute_html.to_s.html_safe
    end
    cur_item.cur_date = @cur_date

    if cur_item.loop_format_shirasagi?
      render_list_with_shirasagi(cur_item, default_procedure_loop_html, &block)
    else
      source = cur_item.loop_liquid.presence || default_procedure_loop_liquid
      assigns = { "procedures" => @items.to_a }
      render_list_with_liquid(source, assigns)
    end
  end

  private

  def render_list_with_shirasagi(cur_item, default_loop_html, &block)
    h = []

    h << cur_item.upper_html.html_safe if cur_item.upper_html.present?
    if block_given?
      h << capture(&block)
    else
      h << cur_item.substitute_html.to_s.html_safe if @items.blank?
      if cur_item.loop_setting.present?
        loop_html = cur_item.loop_setting.html
      elsif cur_item.loop_html.present?
        loop_html = cur_item.loop_html
      else
        loop_html = default_loop_html
      end

      @items.each do |item|
        ih = cur_item.render_loop_html(item, html: loop_html)
        h << ih
      end
    end
    h << cur_item.lower_html.html_safe if cur_item.lower_html.present?

    h.join("\n").html_safe
  end

  def render_list_with_liquid(source, assigns)
    template = ::Cms.parse_liquid(source, liquid_registers)

    if @cur_part
      assigns["part"] = @cur_part
    end
    if @cur_node
      assigns["node"] = @cur_node
    end

    template.render(assigns).html_safe
  end
end
