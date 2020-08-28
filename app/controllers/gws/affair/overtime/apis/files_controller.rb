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

    @items = @model.site(@cur_site).user(@user).where(
      workflow_state: "approve",
      week_in_compensatory_minute: { "$gt" =>  0 },
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

    @items = @model.site(@cur_site).user(@user).where(
      workflow_state: "approve",
      week_out_compensatory_minute: { "$gt" =>  0 },
      id: { "$nin" => file_ids }
    )
  end
end
