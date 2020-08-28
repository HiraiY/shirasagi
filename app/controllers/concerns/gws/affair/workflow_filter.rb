module Gws::Affair::WorkflowFilter
  extend ActiveSupport::Concern

  private

  def request_approval
    url = request.base_url + params[:url]
    comment = params[:workflow_comment]
    notifier = Gws::Affair::Notifier.new(@item)

    current_level = @item.workflow_current_level
    current_workflow_approvers = @item.workflow_approvers_at(current_level).reject{|approver| approver[:user_id] == @cur_user.id}
    current_workflow_approvers.each do |workflow_approver|

      # deliver_workflow_request
      to_users = Gws::User.where(id: workflow_approver[:user_id]).to_a
      notifier.deliver_workflow_request(to_users, url: url, comment: comment)
    end

    @item.set_workflow_approver_state_to_request
    @item.update
  end

  public

  def request_update
    set_item

    raise "403" unless @item.allowed?(:edit, @cur_user)
    if @item.workflow_requested?
      raise "403" unless @item.allowed?(:reroute, @cur_user)
    end

    @item.approved = nil
    if params[:workflow_agent_type].to_s == "agent"
      @item.workflow_user_id = Gws::User.site(@cur_site).in(id: params[:workflow_users]).first.id
      @item.workflow_agent_id = @cur_user.id
    else
      @item.workflow_user_id = @cur_user.id
      @item.workflow_agent_id = nil
    end
    @item.workflow_state   = @model::WORKFLOW_STATE_REQUEST
    @item.workflow_comment = params[:workflow_comment]
    @item.workflow_pull_up = params[:workflow_pull_up]
    @item.workflow_on_remand = params[:workflow_on_remand]
    save_workflow_approvers = @item.workflow_approvers
    @item.workflow_approvers = params[:workflow_approvers]
    @item.workflow_required_counts = params[:workflow_required_counts]
    @item.workflow_approver_attachment_uses = params[:workflow_approver_attachment_uses]
    @item.workflow_current_circulation_level = 0
    save_workflow_circulations = @item.workflow_circulations
    @item.workflow_circulations = params[:workflow_circulations]
    @item.workflow_circulation_attachment_uses = params[:workflow_circulation_attachment_uses]

    if @item.valid?
      request_approval
      @item.class.destroy_workflow_files(save_workflow_approvers)
      @item.class.destroy_workflow_files(save_workflow_circulations)
      render json: { workflow_state: @item.workflow_state }
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end
  end

  def restart_update
    set_item

    raise "403" unless @item.allowed?(:edit, @cur_user)

    @item.approved = nil
    if params[:workflow_agent_type].to_s == "agent"
      @item.workflow_user_id = Gws::User.site(@cur_site).in(id: params[:workflow_users]).first.id
      @item.workflow_agent_id = @cur_user.id
    else
      @item.workflow_user_id = @cur_user.id
      @item.workflow_agent_id = nil
    end
    @item.workflow_state = @model::WORKFLOW_STATE_REQUEST
    @item.workflow_comment = params[:workflow_comment]
    save_workflow_approvers = @item.workflow_approvers
    copy = @item.workflow_approvers.to_a
    copy.each do |approver|
      approver[:state] = @model::WORKFLOW_STATE_PENDING
      approver[:comment] = ''
      approver[:file_ids] = nil
    end
    @item.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)
    @item.workflow_current_circulation_level = 0
    save_workflow_circulations = @item.workflow_circulations
    copy = @item.workflow_circulations.to_a
    copy.each do |circulation|
      circulation[:state] = @model::WORKFLOW_STATE_PENDING
      circulation[:comment] = ''
      circulation[:file_ids] = nil
    end
    @item.workflow_circulations = Workflow::Extensions::WorkflowCirculations.new(copy)

    if @item.save
      request_approval
      @item.class.destroy_workflow_files(save_workflow_approvers)
      @item.class.destroy_workflow_files(save_workflow_circulations)
      render json: { workflow_state: @item.workflow_state }
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end
  end

  def approve_update
    set_item

    raise "403" unless @item.allowed?(:approve, @cur_user)

    save_level = @item.workflow_current_level
    comment = params[:remand_comment]
    file_ids = params[:workflow_file_ids]
    opts = { comment: comment, file_ids: file_ids }
    if params[:action] == 'pull_up_update'
      @item.pull_up_workflow_approver_state(@cur_user, opts)
    else
      @item.approve_workflow_approver_state(@cur_user, opts)
    end

    if @item.finish_workflow?
      @item.approved = Time.zone.now
      @item.workflow_state = @model::WORKFLOW_STATE_APPROVE
      @item.state = "approve"
    end

    if !@item.save
      render json: @item.errors.full_messages, status: :unprocessable_entity
      return
    end

    current_level = @item.workflow_current_level
    if save_level != current_level
      # escalate workflow
      request_approval
    end

    workflow_state = @item.workflow_state
    if workflow_state == @model::WORKFLOW_STATE_APPROVE
      # finished workflow
      to_user_ids = ([ @item.workflow_user_id, @item.workflow_agent_id ].compact) - [@cur_user.id]
      if to_user_ids.present?
        notify_user_ids = to_user_ids.select{|user_id| Gws::User.find(user_id).use_notice?(@item)}.uniq
        if notify_user_ids.present?

          # deliver_workflow_approve
          url = request.base_url + params[:url]
          comment = params[:remand_comment]
          to_users = Gws::User.in(id: notify_user_ids).to_a

          notifier = Gws::Affair::Notifier.new(@item)
          notifier.deliver_workflow_approve(to_users, url: url, comment: comment)

        end
      end

      if @item.move_workflow_circulation_next_step
        current_circulation_users = @item.workflow_current_circulation_users.nin(id: @cur_user.id).active
        current_circulation_users = current_circulation_users.select{|user| user.use_notice?(@item)}
        if current_circulation_users.present?

          # deliver_workflow_circulations
          url = request.base_url + params[:url]
          comment = params[:remand_comment]

          notifier = Gws::Affair::Notifier.new(@item)
          notifier.deliver_workflow_circulations(current_circulation_users, url: url, comment: comment)

        end
        @item.save
      end

      if @item.try(:branch?) && @item.state == "public"
        @item.delete
      end
    end

    if @item.state == "approve"
      set_week_in_leave_file
      set_week_out_leave_file
      delete_leave_file
    end

    render json: { workflow_state: workflow_state }
  end

  alias pull_up_update approve_update

  def remand_update
    set_item

    raise "403" unless @item.allowed?(:approve, @cur_user)

    @item.remand_workflow_approver_state(@cur_user, params[:remand_comment])
    if !@item.save
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end

    begin
      recipients = []
      if @item.workflow_state == @model::WORKFLOW_STATE_REMAND
        recipients << @item.workflow_user_id
        recipients << @item.workflow_agent_id if @item.workflow_agent_id.present?
      else
        prev_level_approvers = @item.workflow_approvers_at(@item.workflow_current_level)
        recipients += prev_level_approvers.map { |hash| hash[:user_id] }
      end
      recipients -= [@cur_user.id]

      notify_user_ids = recipients.select{|user_id| Gws::User.find(user_id).use_notice?(@item)}.uniq
      if notify_user_ids.present?

        # deliver_workflow_remand
        url = request.base_url + params[:url]
        comment = params[:remand_comment]
        to_users = Gws::User.and_enabled.in(id: notify_user_ids).to_a

        notifier = Gws::Affair::Notifier.new(@item)
        notifier.deliver_workflow_remand(to_users, url: url, comment: comment)

      end
    end
    render json: { workflow_state: @item.workflow_state }
  end

  def request_cancel
    set_item

    raise "403" unless @item.allowed?(:edit, @cur_user)

    return if request.get?

    @item.approved = nil
    # @item.workflow_user_id = nil
    @item.workflow_state = @model::WORKFLOW_STATE_CANCELLED

    @item.skip_history_backup = true if @item.respond_to?(:skip_history_backup)
    render_update @item.save, notice: t('workflow.notice.request_cancelled'), render: :request_cancel
  end

  def seen_update
    set_item

    comment = params[:remand_comment]
    file_ids = params[:workflow_file_ids]

    if !@item.update_current_workflow_circulation_state(@cur_user, "seen", comment: comment, file_ids: file_ids)
      @item.errors.add :base, :unable_to_update_cirulaton_state
      render json: @item.errors.full_messages, status: :unprocessable_entity
      return
    end

    to_users = ([ @item.workflow_user, @item.workflow_agent ].compact) - [@cur_user]
    to_users.select!{|user| user.use_notice?(@item)}

    if (comment.present? || file_ids.present?) && to_users.present?

      # deliver_workflow_comment
      url = request.base_url + params[:url]
      to_users = Gws::User.and_enabled.in(id: notify_user_ids).to_a

      notifier = Gws::Affair::Notifier.new(@item)
      notifier.deliver_workflow_comment(to_users, url: url, comment: comment)

    end

    if @item.workflow_current_circulation_completed? && @item.move_workflow_circulation_next_step
      current_circulation_users = @item.workflow_current_circulation_users.nin(id: @cur_user.id).active
      current_circulation_users = current_circulation_users.select{|user| user.use_notice?(@item)}
      if current_circulation_users.present?

        # deliver_workflow_circulations
        url = request.base_url + params[:url]

        notifier = Gws::Affair::Notifier.new(@item)
        notifier.deliver_workflow_circulations(current_circulation_users, url: url, comment: comment)

      end
    end

    if !@item.save
      render json: @item.errors.full_messages, status: :unprocessable_entity
      return
    end

    render json: { workflow_state: @item.workflow_state }
  end

  def set_week_in_leave_file
    return if !@item.try(:week_in_compensatory_minute)
    if @item.week_in_compensatory_minute > 0
      if Gws::Affair::LeaveFile.where(week_out_compensatory_file_id: @item.id).first.present?
        @leave_file = Gws::Affair::LeaveFile.where(week_out_compensatory_file_id: @item.id).first
      elsif Gws::Affair::LeaveFile.where(week_in_compensatory_file_id: @item.id).first.present?
        @leave_file = Gws::Affair::LeaveFile.where(week_in_compensatory_file_id: @item.id).first
      elsif Gws::Affair::LeaveFile.where(week_in_compensatory_file_id: @item.id).first.blank?
        return @leave_file = Gws::Affair::LeaveFile.create(
          cur_user: @item.user,
          cur_site: @item.site,
          leave_type: "week_in_compensatory_leave",
          week_in_compensatory_file_id: @item.id,
          start_at: @item.week_in_start_at,
          end_at: @item.week_in_end_at,
          permission_level: @item.permission_level,
          groups_hash: @item.groups_hash,
          users_hash: @item.users_hash,
          group_ids: @item.user.group_ids,
          user_ids: [@item.user.id],
          workflow_user_id: @item.workflow_user_id,
          workflow_state: @item.workflow_state,
          workflow_approvers: @item.workflow_approvers,
          workflow_required_counts: @item.workflow_required_counts,
          workflow_circulations: @item.workflow_circulations,
          workflow_current_circulation_level: @item.workflow_current_circulation_level,
          approved: @item.approved
        )
      end
      set_week_in_params(@item)
      @leave_file.update(
        cur_user: @item.user,
        cur_site: @item.site,
        leave_type: @leave_type,
        week_in_compensatory_file_id: @week_in_compensatory_file_id,
        week_out_compensatory_file_id: @week_out_compensatory_file_id,
        start_at_date: @start_at_date,
        start_at_hour: @start_at_hour,
        start_at_minute: @start_at_minute,
        end_at_date: @end_at_date,
        end_at_hour: @end_at_hour,
        end_at_minute: @end_at_minute,
        permission_level: @item.permission_level,
        groups_hash: @item.groups_hash,
        users_hash: @item.users_hash,
        group_ids: @item.user.group_ids,
        user_ids: [@item.user.id],
        workflow_user_id: @item.workflow_user_id,
        workflow_state: @item.workflow_state,
        workflow_approvers: @item.workflow_approvers,
        workflow_required_counts: @item.workflow_required_counts,
        workflow_circulations: @item.workflow_circulations,
        workflow_current_circulation_level: @item.workflow_current_circulation_level,
        approved: @item.approved
      )
    end
  end

  def set_week_out_leave_file
    return if !@item.try(:week_out_compensatory_minute)
    if @item.week_out_start_at_date && @item.week_out_compensatory_minute > 0
      if Gws::Affair::LeaveFile.where(week_in_compensatory_file_id: @item.id).first.present?
        @leave_file = Gws::Affair::LeaveFile.where(week_in_compensatory_file_id: @item.id).first
      elsif Gws::Affair::LeaveFile.where(week_out_compensatory_file_id: @item.id).first.present?
        @leave_file = Gws::Affair::LeaveFile.where(week_out_compensatory_file_id: @item.id).first
      elsif Gws::Affair::LeaveFile.where(week_out_compensatory_file_id: @item.id).first.blank?
        return @leave_file = Gws::Affair::LeaveFile.create(
          cur_user: @item.user,
          cur_site: @item.site,
          leave_type: "week_out_compensatory_leave",
          week_out_compensatory_file_id: @item.id,
          start_at: @item.week_out_start_at,
          end_at: @item.week_out_end_at,
          permission_level: @item.permission_level,
          groups_hash: @item.groups_hash,
          users_hash: @item.users_hash,
          group_ids: @item.user.group_ids,
          user_ids: [@item.user.id],
          workflow_user_id: @item.workflow_user_id,
          workflow_state: @item.workflow_state,
          workflow_approvers: @item.workflow_approvers,
          workflow_required_counts: @item.workflow_required_counts,
          workflow_circulations: @item.workflow_circulations,
          workflow_current_circulation_level: @item.workflow_current_circulation_level,
          approved: @item.approved
        )
      end
      set_week_out_params(@item)
      @leave_file.update(
        cur_user: @item.user,
        cur_site: @item.site,
        leave_type: @leave_type,
        week_in_compensatory_file_id: @week_in_compensatory_file_id,
        week_out_compensatory_file_id: @week_out_compensatory_file_id,
        start_at_date: @start_at_date,
        start_at_hour: @start_at_hour,
        start_at_minute: @start_at_minute,
        end_at_date: @end_at_date,
        end_at_hour: @end_at_hour,
        end_at_minute: @end_at_minute,
        permission_level: @item.permission_level,
        groups_hash: @item.groups_hash,
        users_hash: @item.users_hash,
        group_ids: @item.user.group_ids,
        user_ids: [@item.user.id],
        workflow_user_id: @item.workflow_user_id,
        workflow_state: @item.workflow_state,
        workflow_approvers: @item.workflow_approvers,
        workflow_required_counts: @item.workflow_required_counts,
        workflow_circulations: @item.workflow_circulations,
        workflow_current_circulation_level: @item.workflow_current_circulation_level,
        approved: @item.approved
      )
    end
  end

  def delete_leave_file
    return if !@item.try(:week_in_compensatory_minute)
    return if !@item.try(:week_out_compensatory_minute)
    if @item.week_in_compensatory_minute == 0 && @item.week_out_compensatory_minute == 0
      if Gws::Affair::LeaveFile.where(week_out_compensatory_file_id: @item.id).first.present?
        Gws::Affair::LeaveFile.where(week_out_compensatory_file_id: @item.id).first.delete
      elsif Gws::Affair::LeaveFile.where(week_in_compensatory_file_id: @item.id).first.present?
        Gws::Affair::LeaveFile.where(week_in_compensatory_file_id: @item.id).first.delete
      end
    elsif @item.week_out_compensatory_minute > 0 && @item.week_out_start_at.blank?
      if Gws::Affair::LeaveFile.where(week_out_compensatory_file_id: @item.id).first.present?
        Gws::Affair::LeaveFile.where(week_out_compensatory_file_id: @item.id).first.delete
      elsif Gws::Affair::LeaveFile.where(week_in_compensatory_file_id: @item.id).first.present?
        Gws::Affair::LeaveFile.where(week_in_compensatory_file_id: @item.id).first.delete
      end
    end
  end

  def set_week_in_params(item)
    @leave_type = "week_in_compensatory_leave"
    @week_in_compensatory_file_id = item.id
    @week_out_compensatory_file_id = nil
    @start_at_date = item.week_in_start_at_date
    @start_at_hour = item.week_in_start_at_hour
    @start_at_minute = item.week_in_start_at_minute
    @end_at_date = item.week_in_end_at_date
    @end_at_hour = item.week_in_end_at_hour
    @end_at_minute = item.week_in_end_at_minute
  end

  def set_week_out_params(item)
    @leave_type = "week_out_compensatory_leave"
    @week_in_compensatory_file_id = nil
    @week_out_compensatory_file_id = item.id
    @start_at_date = item.week_out_start_at_date
    @start_at_hour = item.week_out_start_at_hour
    @start_at_minute = item.week_out_start_at_minute
    @end_at_date = item.week_out_end_at_date
    @end_at_hour = item.week_out_end_at_hour
    @end_at_minute = item.week_out_end_at_minute
  end
end
