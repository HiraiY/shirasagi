module Gws::Monitor::CommentFilter
  extend ActiveSupport::Concern

  included do
    model Gws::Monitor::Post

    before_action :set_category
    before_action :set_topic

    before_action :check_creatable, only: %i[new create]
    before_action :check_updatable, only: %i[edit update]
    before_action :check_destroyable, only: %i[delete destroy]

    navi_view "gws/monitor/main/navi"
    menu_view "gws/monitor/comments/menu"
  end

  private

  # override Gws::CrudFilter#append_view_paths
  def append_view_paths
    append_view_path "app/views/gws/monitor/comments"
    super
  end

  def set_category
    if params[:category].present? && params[:category] != '-'
      @category ||= Gws::Monitor::Category.site(@cur_site).where(id: params[:category]).first
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    { name: @cur_group.section_name }
  end

  def set_topic
    @topic ||= Gws::Monitor::Topic.site(@cur_site).topic.find(params[:topic_id])
  end

  def set_item
    @item ||= begin
      set_topic

      item = @topic.descendants.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def check_creatable
    return if @topic.allowed?(:edit, @cur_user, site: @cur_site) && @topic.owned?(@cur_user)

    raise '403' unless @topic.permit_comment?
    raise '403' unless @topic.public?
    raise '403' unless @topic.attended?(@cur_group)
    raise '403' unless Gws::Monitor::Post.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def check_updatable
    return if @topic.allowed?(:edit, @cur_user, site: @cur_site)

    raise '403' unless @topic.attended?(@cur_group)
    raise '403' unless @item.user_group_id == @cur_group.id
    raise '403' unless Gws::Monitor::Post.allowed?(:edit, @cur_user, site: @cur_site)

    raise "404" if @item.public?
    raise "404" if @item.not_applicable_post?
  end

  def check_destroyable
    return if @topic.allowed?(:delete, @cur_user, site: @cur_site)

    raise '403' unless @topic.attended?(@cur_group)
    raise '403' unless @item.user_group_id == @cur_group.id
    raise '403' unless Gws::Monitor::Post.allowed?(:delete, @cur_user, site: @cur_site)
  end

  def get_topic_path
    if request.path.include?("/management/")
      gws_monitor_management_topic_path(id: @topic)
    else
      gws_monitor_topic_path(id: @topic)
    end
  end

  def public_answers_blank?
    @topic.descendants.and_public.where(user_group_id: @cur_group.id).blank?
  end

  def create_post(parent, post_type, extra_attributes = {})
    @item = @model.new pre_params.merge(get_params.merge(extra_attributes))
    @item.topic = @topic
    @item.parent = parent
    @item.post_type = post_type
    @item.group_ids = [ @cur_group.id ]
    result = @item.save

    if result && @item.public? && !@item.reply_post?
      @topic.answer_state_hash[@cur_group.id.to_s] = @item.answer_post? ? "answered" : "question_not_applicable"
      @topic.save
    end

    location = get_topic_path
    if result && params[:publish].present?
      location = { action: :publish, id: @item }
    end
    render_create result, { location: location }
  end

  public

  def index
    redirect_to get_topic_path
  end

  def show
    render
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
    @item.topic = @topic
    @item.parent = @topic
    @item.post_type = "answer"
  end

  def create
    create_post(@topic, "answer")
  end

  def edit
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)

    render_update @item.update, {location: get_topic_path}
  end

  def delete
    raise "404" unless @item.closed?
    render
  end

  def destroy
    raise "404" unless @item.closed?
    render_destroy @item.destroy, {location: get_topic_path}
  end

  def not_applicable
    if request.get?
      @item = @model.new pre_params.merge(fix_params)
      @item.post_type = "not_applicable"
      @item.text = I18n.t("gws/monitor.options.answer_state.question_not_applicable")
      @item.text_type = "plain"
      @item.group_ids = [ @cur_group.id ]

      render
      return
    end

    create_post(@topic, "not_applicable", text: I18n.t("gws/monitor.options.answer_state.question_not_applicable"))
  end

  def publish
    set_item
    raise "404" unless @item.closed?
    raise "403" unless @item.allowed?(:release, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    @item.attributes = get_params if params[:item].present?
    @item.state = "public"
    result = @item.save

    if result && @item.public? && !@item.reply_post?
      @topic.answer_state_hash[@cur_group.id.to_s] = @item.answer_post? ? "answered" : "question_not_applicable"
      @topic.save
    end

    if result && @item.public? && @item.reply_post? && @item.parent.answer_post? && @item.in_answer_required == "required"
      @topic.answer_state_hash[@item.parent.user_group_id.to_s] = "public"
      @topic.save
    end

    render_create result, { location: get_topic_path }
  end

  def depublish
    set_item
    raise "404" unless @item.public?
    raise "403" unless @item.allowed?(:release, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    @item.state = "draft"
    result = @item.save

    if result && @item.closed? && public_answers_blank?
      @topic.answer_state_hash[@cur_group.id.to_s] = "public"
      @topic.save
    end

    render_create result, { location: get_topic_path }
  end

  def reply
    set_item
    @reply_item = @item

    if request.get?
      @item = @model.new pre_params.merge(fix_params)
      @item.topic = @topic
      @item.parent = @reply_item
      @item.post_type = request.path.include?("/management/") ? "reply" : "answer"
      render
      return
    end

    create_post(@reply_item, request.path.include?("/management/") ? "reply" : "answer")
  end
end
