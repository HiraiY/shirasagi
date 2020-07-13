module Gws::Monitor::CommentFilter
  extend ActiveSupport::Concern

  included do
    model Gws::Monitor::Post

    before_action :set_category
    before_action :set_topic_and_parent

    before_action :check_creatable, only: %i[new create]
    before_action :check_updatable, only: %i[edit update]
    before_action :check_destroyable, only: %i[delete destroy]

    navi_view "gws/monitor/main/navi"
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
    { cur_user: @cur_user, cur_site: @cur_site, topic_id: params[:topic_id], parent_id: params[:parent_id] }
  end

  def pre_params
    { name: @cur_group.section_name }
  end

  def set_topic_and_parent
    @topic ||= Gws::Monitor::Topic.site(@cur_site).topic.find(params[:topic_id])
    @parent ||= @model.site(@cur_site).find(params[:parent_id])
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
  end

  def check_destroyable
    return if @topic.allowed?(:delete, @cur_user, site: @cur_site)

    raise '403' unless @topic.attended?(@cur_group)
    raise '403' unless @item.user_group_id == @cur_group.id
    raise '403' unless Gws::Monitor::Post.allowed?(:delete, @cur_user, site: @cur_site)
  end

  def get_show_path
    if request.path.include?("/management/")
      gws_monitor_management_topic_path(id: @topic)
    else
      gws_monitor_topic_path(id: @topic)
    end
  end

  public

  def index
    redirect_to get_show_path
  end

  def show
    redirect_to get_show_path
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
  end

  def create
    @item = @model.new get_params
    @item.post_type = "answer"
    @item.group_ids = [ @cur_group.id ]
    result = @item.save

    if result && @item.public?
      if @item.answer_post?
        @topic.answer_state_hash[@cur_group.id.to_s] = "answered"
        @topic.save
      elsif @item.not_applicable_post?
        @topic.answer_state_hash[@cur_group.id.to_s] = "question_not_applicable"
        @topic.save
      end
    end

    render_create result, { location: get_show_path }
  end

  def edit
    raise "404" if !@item.closed? || !@item.answer_post?
    render
  end

  def update
    raise "404" if !@item.closed? || !@item.answer_post?

    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)

    render_update @item.update, {location: get_show_path}
  end

  def delete
    raise "404" unless @item.closed?
    render
  end

  def destroy
    raise "404" unless @item.closed?
    render_destroy @item.destroy, {location: get_show_path}
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

    @item = @model.new get_params
    @item.post_type = "not_applicable"
    @item.text = I18n.t("gws/monitor.options.answer_state.question_not_applicable")
    @item.text_type = "plain"
    @item.group_ids = [ @cur_group.id ]
    result = @item.save

    if result && @item.public?
      if @item.answer_post?
        @topic.answer_state_hash[@cur_group.id.to_s] = "answered"
        @topic.save
      elsif @item.not_applicable_post?
        @topic.answer_state_hash[@cur_group.id.to_s] = "question_not_applicable"
        @topic.save
      end
    end

    render_create result, { location: get_show_path, notice: I18n.t("gws/monitor.notice.question_not_applicable") }
  end

  def publish
    set_item
    raise "404" unless @item.closed?
    raise "403" unless @item.allowed?(:release, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    @item.state = "public"
    result = @item.save

    if result && @item.public?
      @topic.answer_state_hash[@cur_group.id.to_s] = "answered"
      @topic.save
    end

    render_create result, { location: get_show_path }
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

    if result && @item.closed?
      @topic.answer_state_hash[@cur_group.id.to_s] = "public"
      @topic.save
    end

    render_create result, { location: get_show_path }
  end
end
