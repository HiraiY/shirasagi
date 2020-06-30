class Gws::Facility::PlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Facility::PlanFilter
  include Gws::Memo::NotificationFilter

  navi_view "gws/facility/main/navi"

  before_action :set_category
  before_action :set_facilities
  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :soft_delete]

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_facility_label || t('modules.gws/facility'), gws_facility_main_path]
    @crumbs << [t('modules.addons.gws/schedule/facility'), gws_facility_schedule_path]
  end

  def set_category
    set_facility_category
    #set_schedule_category
  end

  def set_facilities
    @facilities = Gws::Facility::Item.site(@cur_site).
      readable(@cur_user, site: @cur_site).
      active
    @facilities = @facilities.in(category_id: category_ids)

    @manage_facilities = Gws::Facility::Item.site(@cur_site).
      where(user_ids: @cur_user.id).
      active
    @manage_facilities = @manage_facilities.in(category_id: category_ids)
  end

  def set_items
    @items = Gws::Schedule::Plan.site(@cur_site).without_deleted.
      in(facility_ids: @facilities.map(&:id)).
      search(params[:s]).
      order_by(start_at: -1)

    if params[:state] == "all"
      #
    elsif params[:state] == "approve"
      @items = @items.where(approval_state: "request")
      @items = @items.in(facility_ids: @manage_facilities.map(&:id))
    elsif params[:state] == "request"
      @items = @items.where(approval_state: "request")
      @items = @items.or([{ user_id: @cur_user.id }, { "member_ids" => { "$in" => [@cur_user.id] }}])
    elsif params[:state] == "loan"
      @items = @items.on_loan.or([{ approval_state: "approve" }, { :approval_state.exists => false }])
    end
  end

  def redirection_url
    nil
  end

  public

  def index
  end

  def show
    raise "403" unless @item.readable?(@cur_user, site: @cur_site)
    render
  end 

  def events
    @events = @items.map { |m| m.calendar_format(@cur_user, @cur_site) }
  end

  def download
    filename = "gws_schedule_facility_plans_#{Time.zone.now.to_i}.csv"
    response.status = 200
    send_enum(
      Gws::Schedule::PlanCsv::Exporter.enum_csv(@items, site: @cur_site, user: @cur_user),
      type: 'text/csv; charset=Shift_JIS', filename: filename
    )
  end

  def destroy_all
    soft_delete_all
  end

  def soft_delete_all
    raise "400" if @selected_items.blank?

    entries = @selected_items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site)
        item.attributes = fix_params

        # soft_delete
        item.deleted = Time.zone.now
        #item.edit_range = params.dig(:item, :edit_range)
        result = item.save

        next if result
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end
end

