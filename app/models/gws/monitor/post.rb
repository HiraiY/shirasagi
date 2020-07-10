class Gws::Monitor::Post
  include Gws::Referenceable
  include Gws::Monitor::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Monitor::DescendantsFileInfo
  include Gws::Addon::History
  include Gws::Addon::Monitor::Category
  include SS::Release
  include Gws::GroupPermission

  self.default_release_state = 'draft'

  field :post_type, type: String

  validates :post_type, inclusion: { in: %w(answer not_applicable), allow_blank: true }

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::MonitorPostJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::MonitorPostJob.callback

  # override SS::Release#state_options
  def state_options
    %w(draft public closed).map { |m| [I18n.t("gws/monitor.options.state.#{m}"), m] }
  end

  def not_applicable_post?
    post_type == "not_applicable"
  end

  def answer_post?
    !not_applicable_post?
  end
end
