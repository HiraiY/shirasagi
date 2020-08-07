class Gws::Affair::WorkingTime::CalendarController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair::ShiftRecord

  menu_view nil

  navi_view "gws/affair/main/navi"

  append_view_path 'app/views/gws/affair/working_time/calendar'

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t("modules.gws/affair/working_time"), gws_affair_working_time_calendar_path]
  end

  def set_user
    @user = Gws::User.find(params[:user]) rescue nil
  end

  def set_cur_month
    raise '404' if params[:year_month].blank? || params[:year_month].length != 6

    year = params[:year_month][0..3]
    month = params[:year_month][4..5]
    @cur_month = Time.zone.parse("#{year}/#{month}/01")
  end

  def set_query
    @s ||= OpenStruct.new params[:s]

    @groups = Gws::Group.in_group(@cur_site).active
    @year = (params.dig(:s, :year).presence || @cur_month.year).to_i
    @month = (params.dig(:s, :month).presence || @cur_month.month).to_i
    @group_id = params.dig(:s, :group_id).presence

    if @group_id.present?
      @group = @groups.where(id: @group_id).first
    else
      @group = @cur_user.gws_main_group(@cur_site)
    end
    @group ||= @cur_site
    @s[:group_id] ||= @group.id

    # 所属グループ権限のみの場合は自グループのみ
    if !Gws::Affair::ShiftCalendar.allowed_other?(:edit, @cur_user, site: @cur_site)
      @groups = [@group]
    end

    #シフト勤務カレンダーがあるユーザーのみ
    user_ids = Gws::Affair::ShiftCalendar.site(@cur_site).pluck(:user_id)
    @users = Gws::User.active.in(group_ids: [@group.id]).in(id: user_ids).order_by_title(@cur_site)

    @s[:year] ||= @year
    @s[:month] ||= @month
  end

  public

  def index
    set_cur_month
    set_query
  end

  def shift_record
    set_user
    set_cur_month

    @cur_date = @cur_month.change(day: params[:day])
    @shift_calendar = @user.shift_calendar(@cur_site)

    @item = @shift_calendar.shift_record(@cur_date) || @model.new
    @item.shift_calendar_id = @shift_calendar.id
    @item.date = @cur_date

    if request.get?
      render file: 'shift_record', layout: false
      return
    end

    @item.attributes = get_params
    if @item.valid?

      if @item.same_default?
        @item.destroy
      else
        @item.save
      end

      location = url_for(action: :index)
      notice = t('ss.notice.saved')

      respond_to do |format|
        flash[:notice] = notice
        format.html do
          if request.xhr?
            render json: { location: location }, status: :ok, content_type: json_content_type
          else
            redirect_to location
          end
        end
        format.json { render json: { location: location }, status: :ok, content_type: json_content_type }
      end
    else
      respond_to do |format|
        format.html { render file: 'shift_record', layout: false, status: :unprocessable_entity }
        format.json { render json: @cell.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
      end
    end
  end
end
