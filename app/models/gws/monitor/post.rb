class Gws::Monitor::Post
  include Gws::Referenceable
  include Gws::Monitor::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Monitor::DescendantsFileInfo
  include Gws::Addon::Monitor::Approver
  include Gws::Addon::History
  include SS::Release
  include Gws::GroupPermission

  self.approver_user_class = Gws::User
  self.default_release_state = 'draft'
  self.public_states = %w(public approve)

  attr_accessor :in_answer_required

  field :post_type, type: String

  permit_params :post_type, :in_answer_required

  validates :post_type, inclusion: { in: %w(answer not_applicable reply), allow_blank: true }
  validates :topic_id, presence: true
  validates :parent_id, presence: true

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::MonitorPostJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::MonitorPostJob.callback

  after_save :update_topic_answer_state, if: ->{ state_changed? && public? }

  # override SS::Release#state_options
  def state_options
    %w(draft public closed approve).map { |m| [I18n.t("gws/monitor.options.state.#{m}"), m] }
  end

  def in_answer_required_options
    %w(not_required required).map { |m| [I18n.t("gws/monitor.options.in_answer_required.#{m}"), m] }
  end

  def not_applicable_post?
    post_type == "not_applicable"
  end

  def reply_post?
    post_type == "reply"
  end

  def answer_post?
    !not_applicable_post? && !reply_post?
  end

  def workflow_wizard_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair_overtime_wizard_path(site: site.id, id: id)
  end

  def workflow_pages_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair_overtime_file_path(site: site.id, id: id, state: "all")
  end

  private

  def update_topic_answer_state
    topic = self.topic
    return if topic.blank?

    answer_state_key = user_group_id.to_s
    current_answer_state = new_answer_state = topic.answer_state_hash[answer_state_key]
    if public? && !reply_post?
      new_answer_state = answer_post? ? "answered" : "question_not_applicable"
    end

    if current_answer_state != new_answer_state
      topic.answer_state_hash.update(answer_state_key => new_answer_state)
      topic.save
    end
  end
end
