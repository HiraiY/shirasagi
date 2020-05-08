module Gws::RegistrationHelper

  def required_label
    content_tag('span', t("ss.required_field"), class: :required)
  end

  def remarks(key, html_wrap = true, options = {})
    modelnames = @model.ancestors.select { |x| x.respond_to?(:model_name) }
    msg = ""
    modelnames.each do |modelname|
      msg = I18n.t("remarks.#{modelname.model_name.i18n_key}.#{key}", default: "")
      break if msg.present?
    end
    return msg if msg.blank? || !html_wrap
    msg = [msg].flatten if msg.class != Array
    msg = msg.map { |d| I18n.interpolate(d, options) }
    list = msg.map { |d| "<li>" + d.to_s.gsub(/\r\n|\n/, "<br />") + "<br /></li>" }

    h = []
    h << %(<div class="remarks">)
    h << %(<ul>)
    h << list
    h << %(</ul>)
    h << %(</div>)
    h.join("\n").html_safe
  end
end
