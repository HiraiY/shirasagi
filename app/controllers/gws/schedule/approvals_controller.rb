class Gws::Schedule::ApprovalsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  #include Gws::Memo::NotificationFilter

  model Gws::Schedule::Approval

  navi_view "gws/schedule/main/navi"

  private

  def set_cur_schedule
    @cur_schedule ||= Gws::Schedule::Plan.find(params[:plan_id])
    @cur_schedule.cur_site = @cur_site
  end

  def set_facility
    @cur_facility = Gws::Facility::Item.where(id: params.dig(:item, :facility_id).to_i).first
  end

  def set_target_user
    set_cur_schedule

    @target_user = @cur_schedule.members.where(id: params[:user_id]).first
    @target_user ||= begin
      member_ids = @cur_schedule.member_custom_groups.pluck(:member_ids).flatten
      Gws::User.in(id: member_ids).where(id: params[:user_id]).first
    end

    raise '404' unless @target_user

    @target_user.cur_site = @cur_site
  end

  def fix_params
    set_cur_schedule
    set_target_user

    ret = { cur_user: @target_user }
    ret[:approval_state] = params.dig(:item, :approval_state) if params[:item].present?
    ret
  end

  def set_item
    set_cur_schedule
    set_target_user
    set_facility

    cond = { user_id: @target_user.id }
    cond[:facility_id] = @cur_facility.id if @cur_facility

    @item = @cur_schedule.approvals.where(cond).first
    @item ||= @cur_schedule.approvals.new
    @item.attributes = fix_params
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def post_comment
    return if params[:comment].blank?

    safe_params = params.require(:comment).permit(Gws::Schedule::Comment.permitted_fields)
    return if safe_params[:text].blank?

    safe_params.reverse_merge!(
      cur_site: @cur_site, cur_user: @target_user, cur_schedule: @cur_schedule, text_type: 'plain'
    )
    Gws::Schedule::Comment.create(safe_params)
  end

  def send_approval_approve_mail
    notifiable = @cur_schedule.respond_to?(:notify_enabled?) ? @cur_schedule.notify_enabled? : true
    return if notifiable

    exclusion_user_ids = @cur_schedule.members.reject{|user| user.use_notice?(@cur_schedule)}.map(&:id)
    exclusion_user_ids << @cur_user.id
    exclusion_user_ids.uniq!

    Gws::Schedule::Notifier::Approval.deliver_approve!(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
      to_users: @cur_schedule.members.nin(id: exclusion_user_ids), item: @cur_schedule,
      url: gws_schedule_plan_url(id: @cur_schedule),
      comment: params.dig(:comment, :text)
    ) rescue nil
  end

  def send_approval_deny_mail
    notifiable = @cur_schedule.respond_to?(:notify_enabled?) ? @cur_schedule.notify_enabled? : true
    return if notifiable

    exclusion_user_ids = @cur_schedule.members.reject{|user| user.use_notice?(@cur_schedule)}.map(&:id)
    exclusion_user_ids << @cur_user.id
    exclusion_user_ids.uniq!

    Gws::Schedule::Notifier::Approval.deliver_remand!(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
      to_users: @cur_schedule.members.nin(id: exclusion_user_ids), item: @cur_schedule,
      url: gws_schedule_plan_url(id: @cur_schedule),
      comment: params.dig(:comment, :text)
    ) rescue nil
  end

  public

  def edit
    raise "403" unless @cur_schedule.member?(@cur_user) ||
                       @cur_schedule.allowed_for_managers?(:edit, @cur_user, site: @cur_site) ||
                       @cur_schedule.approval_member?(@cur_user)
    @item.valid?
    render(layout: 'ss/ajax')
  end

  def update
    raise "403" unless @cur_schedule.member?(@cur_user) ||
                       @cur_schedule.allowed_for_managers?(:edit, @cur_user, site: @cur_site) ||
                       @cur_schedule.approval_member?(@cur_user)
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)

    if @cur_schedule.save
      post_comment

      if @cur_schedule.approval_state == 'approve'
        send_approval_approve_mail
      elsif params.dig(:item, :approval_state) == 'deny'
        send_approval_deny_mail
      end

      #location = CGI.unescapeHTML(params[:redirect_to])
      flash[:notice] = t("ss.notice.saved")
      render json: @cur_schedule.to_json, status: :ok
    else
      render json: @cur_schedule.errors.full_messages, status: :unprocessable_entity
    end
  end
end
