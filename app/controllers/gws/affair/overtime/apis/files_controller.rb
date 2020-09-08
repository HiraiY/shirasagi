class Gws::Affair::Overtime::Apis::FilesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Affair::OvertimeFile

  def week_in
    @user = Gws::User.active.where(id: params[:uid]).first
    if @user.blank?
      @items = []
      return
    end

    @leave_file = Gws::Affair::LeaveFile.where(id: params[:id]).first

    file_ids = Gws::Affair::LeaveFile.site(@cur_site).where(workflow_state: "approve").
      pluck(:week_in_compensatory_file_id).compact
    file_ids -= [@leave_file.week_in_compensatory_file_id] if @leave_file

    @items = @model.site(@cur_site).where(
      target_user_id: @user.id,
      workflow_state: "approve",
      week_in_compensatory_minute: { "$gt" => 0 },
      id: { "$nin" => file_ids }
    )
  end

  def week_out
    @user = Gws::User.active.where(id: params[:uid]).first
    if @user.blank?
      @items = []
      return
    end

    @leave_file = Gws::Affair::LeaveFile.where(id: params[:id]).first

    file_ids = Gws::Affair::LeaveFile.site(@cur_site).where(workflow_state: "approve").
      pluck(:week_out_compensatory_file_id).compact
    file_ids -= [@leave_file.week_out_compensatory_file_id] if @leave_file

    number = @cur_site.week_out_compensatory_file_limit || 2
    unit = @cur_site.week_out_compensatory_file_limit_unit || 'month'

    case unit
    when 'day'
      @limit = number.day
    when 'week'
      @limit = number.week
    when 'month'
      @limit = number.month
    when 'year'
      @limit = number.year
    end

    @items = @model.site(@cur_site).where(
      target_user_id: @user.id,
      workflow_state: "approve",
      week_out_compensatory_minute: { "$gt" => 0 },
      id: { "$nin" => file_ids }
    )

    items = []
    @items.each do |item|
      if (item.start_at + @limit).strftime('%Y/%m/%d') >= Time.zone.now.strftime('%Y/%m/%d')
        items << item
      end
    end
    @items = items

    @left_compensatory_minute = @items.sum { |hash| hash[:week_out_compensatory_minute] } / 60.0
  end
end
