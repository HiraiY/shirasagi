class Guide::Procedure
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission
  include SS::TemplateVariable
  include SS::Liquidization
  include Guide::Addon::Question

  seqid :id
  field :name, type: String
  field :link_url, type: String
  field :html, type: String
  field :procedure_location, type: String
  field :belongings, type: SS::Extensions::Words
  field :procedure_applicant, type: SS::Extensions::Words
  field :remarks, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :link_url, :html, :procedure_location, :belongings, :procedure_applicant, :remarks, :order
  validates :name, presence: true, length: { maximum: 40 }

  default_scope -> { order_by(order: 1, name: 1) }

  template_variable_handler(:id, :template_variable_handler_name)
  template_variable_handler(:name, :template_variable_handler_name)
  template_variable_handler(:link_url, :template_variable_handler_name)
  template_variable_handler(:link, :template_variable_handler_link)
  template_variable_handler(:html, :template_variable_handler_html)
  template_variable_handler(:procedure_location, :template_variable_handler_name)
  template_variable_handler(:belongings, :template_variable_handler_name)
  template_variable_handler(:procedure_applicant, :template_variable_handler_name)
  template_variable_handler(:remarks, :template_variable_handler_name)

  liquidize do
    export :id
    export :name
    export :link_url
    export :link do
      link_url.present? ? "<a href=\"#{link_url}\">#{self.name}</a>".html_safe : self.name
    end
    export :html
    export :procedure_location
    export :belongings
    export :procedure_applicant
    export :remarks
  end

  class << self
    def search(params = {})
      criteria = self.all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end

    def to_csv(site, encode = nil)
      CSV.generate do |data|
        data << header
        self.site(site).each { |item| data << row(item) }
      end
    end

    private

    def header
      %w(
        id name link_url html procedure_location belongings procedure_applicant remarks order question_ids
      ).map { |e| t e }
    end

    def row(item)
      item.site ||= site

      [
        item.id,
        item.name,
        item.link_url,
        item.html,
        item.procedure_location,
        item.belongings,
        item.procedure_applicant,
        item.remarks,
        item.order,
        item.questions.pluck(:question).join("\n")
      ]
    end
  end

  def template_variable_handler_name(name, issuer)
    ERB::Util.html_escape self.send(name)
  end

  def template_variable_handler_html(name, issuer)
    return nil unless respond_to?(name)
    self.send(name).present? ? self.send(name).html_safe : nil
  end

  def template_variable_handler_link(name, issuer)
    link_url.present? ? "<a href=\"#{link_url}\">#{self.name}</a>".html_safe : self.name
  end
end
