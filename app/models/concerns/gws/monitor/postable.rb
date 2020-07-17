module Gws::Monitor::Postable
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::GroupPermission
  include Fs::FilePreviewable

  included do
    store_in collection: "gws_monitor_posts"

    attr_accessor :cur_site

    seqid :id
    field :name, type: String
    field :mode, type: String, default: 'thread'
    field :permit_comment, type: String, default: 'allow'
    field :descendants_updated, type: DateTime
    field :severity, type: String
    field :due_date, type: DateTime
    field :spec_config, type: String, default: 'my_group'

    validates :descendants_updated, datetime: true

    belongs_to :topic, class_name: "Gws::Monitor::Topic", inverse_of: :descendants
    belongs_to :parent, class_name: "Gws::Monitor::Post", inverse_of: :children

    has_many :children, class_name: "Gws::Monitor::Post", dependent: :destroy, inverse_of: :parent,
      order: { created: -1 }
    has_many :descendants, class_name: "Gws::Monitor::Post", dependent: :destroy, inverse_of: :topic,
      order: { created: -1 }

    permit_params :name, :mode, :permit_comment, :severity, :due_date, :spec_config
    permit_params :parent_id

    before_validation :set_topic_id, if: ->{ comment? && topic_id.blank? }

    validates :name, presence: true, length: { maximum: 80 }
    validates :mode, inclusion: {in: %w(thread tree)}, unless: :comment?
    validates :permit_comment, inclusion: {in: %w(allow deny)}, unless: :comment?
    validates :severity, inclusion: { in: %w(normal important), allow_blank: true }

    validate :validate_comment, if: :comment?

    before_save :set_descendants_updated, if: -> { topic_id.blank? }
    after_save :update_topic_descendants_updated, if: -> { topic_id.present? }

    scope :topic, ->{ exists parent_id: false }
    scope :topic_comments, ->(topic) { where topic_id: topic.id }
  end

  module ClassMethods
    def search(params)
      methods = %i[search_keyword search_category search_question_state search_answer_state_filter search_approve_state_filter]

      criteria = all
      methods.each do |method|
        criteria = criteria.send(method, params)
      end
      criteria
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in(params[:keyword], :name, :text)
    end

    def search_category(params)
      return all if params.blank? || params[:category].blank?

      category_ids = Gws::Monitor::Category.site(params[:site]).and_name_prefix(params[:category]).pluck(:id)
      all.in(category_ids: category_ids)
    end

    def search_question_state(params)
      return all if params.blank? || params[:question_state].blank?
      all.where(question_state: params[:question_state].to_s)
    end

    def search_answer_state_filter(params)
      return all if params.blank? || params[:answer_state_filter].blank?

      case params[:answer_state_filter].to_s
      when "unanswered"
        all.and_unanswered(params[:group])
      when "answered"
        all.and_answered(params[:group])
      else # "all"
        all
      end
    end

    def search_approve_state_filter(params)
      return all if params.blank? || params[:approve_state_filter].blank?
      return all if params[:approve_state_filter] == "-"

      base_criteria = Gws::Monitor::Post.site(params[:site]).exists(topic_id: true).where(user_group_id: params[:group].id)

      case params[:approve_state_filter].to_s
      when "approve"
        criteria = base_criteria.where(
          workflow_state: 'request',
          workflow_approvers: { '$elemMatch' => { 'user_id' => params[:user].id, 'state' => 'request' } }
        )
      when "request"
        criteria = base_criteria.where(workflow_user_id: params[:user].id)
      else
        criteria = Gws::Monitor::Post.none
      end

      all.in(id: criteria.pluck(:topic_id))
    end
  end

  # Returns the topic.
  def root_post
    parent.nil? ? self : parent.root_post
  end

  # is comment?
  def comment?
    parent_id.present?
  end

  def permit_comment?
    permit_comment == 'allow'
  end

  def new_flag?
    (released.presence || created) > Time.zone.now - site.monitor_new_days.day
  end

  def showable_comment?(cur_user, cur_group)
    # 自部署の回答は閲覧できる。
    return true if user_group_id == cur_group.id

    # 自部署の回答への返信は閲覧できる。
    return true if reply_post? && closest_answer.try(:user_group_id) == cur_group.id

    topic = self.topic
    return false if topic.blank?

    # 管理権限があれば、閲覧できる。
    topic.cur_site = topic.site
    return true if topic.allowed?(:read, cur_user, site: topic.site) && topic.owned?(cur_user)

    # 設定で「他者の回答内容を閲覧可能」となっているの場合、他者の回答が「公開」であれば閲覧できる。
    if topic.spec_config == 'other_groups_and_contents'
      return true if self.public?
    end

    false
  end

  def mode_options
    [
      [I18n.t('gws/monitor.options.mode.thread'), 'thread'],
      [I18n.t('gws/monitor.options.mode.tree'), 'tree']
    ]
  end

  def permit_comment_options
    [
      [I18n.t('gws/monitor.options.permit_comment.allow'), 'allow'],
      [I18n.t('gws/monitor.options.permit_comment.deny'), 'deny']
    ]
  end

  def spec_config_options
    %w(my_group other_groups other_groups_and_contents).map do |v|
      [I18n.t("gws/monitor.options.spec_config.#{v}"), v]
    end
  end

  def severity_options
    %w(normal important).map { |v| [ I18n.t("gws/monitor.options.severity.#{v}"), v ] }
  end

  def becomes_with_topic
    if topic_id.present?
      return self
    end

    becomes_with(Gws::Monitor::Topic)
  end

  def file_previewable?(file, user:, member:)
    return false if user.blank?
    return false if !file_ids.include?(file.id)

    if topic.blank? || topic.id == id
      # cur_group is wanted, but currently unable to obtain it.
      # so all groups which user has are checked.
      ret = user.groups.in_group(site).active.any? do |group|
        attended?(group)
      end
      return ret if ret

      return topic.allowed?(:read, user, site: site)
    end

    user.groups.in_group(site).active.any? do |group|
      showable_comment?(user, group)
    end
  end

  def closest_answer
    @closest_answer ||= _closest_answer
  end

  private

  # topic(root_post)を設定
  def set_topic_id
    self.topic_id = root_post.id
  end

  # コメントを許可しているか検証
  def validate_comment
    return if topic.permit_comment?

    errors.add :base, I18n.t("gws/monitor.errors.denied_comment")
  end

  # 最新レス投稿日時の初期値をトピックのみ設定
  # 明示的に age るケースが発生するかも
  def set_descendants_updated
    self.descendants_updated = updated
  end

  # 最新レス投稿日時、レス更新日時をトピックに設定
  # 明示的に age るケースが発生するかも
  def update_topic_descendants_updated
    return unless topic

    topic.set descendants_updated: updated
  end

  def _closest_answer
    post = parent
    while post.present? && post.topic_id.present?
      return post if post.answer_post? || post.not_applicable_post?

      post = post.parent
    end

    nil
  end

  module ClassMethods
    def readable_setting_included_custom_groups?
      class_variable_get(:@@_readable_setting_include_custom_groups)
    end

    private

    def readable_setting_include_custom_groups
      class_variable_set(:@@_readable_setting_include_custom_groups, true)
    end
  end
end
