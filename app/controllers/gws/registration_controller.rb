class Gws::RegistrationController < ApplicationController
  include Gws::BaseFilter
  include Sns::LoginFilter

  skip_before_action :logged_in?
  before_action :destroy_registration, only: [:verify]

  model Gws::Registration

  private

  def fix_params
    { cur_site: @cur_site, in_protocol: request.protocol, in_host: request.host_with_port }
  end

  def permit_fields
    @model.permitted_fields
  end

  def get_params
    params.require(:item).permit(permit_fields).merge(fix_params)
  end

  def set_item_for_interim(extra_attrs = {})
    @item = item = @model.new get_params.merge(extra_attrs)
    if item.email.present?
      item = @model.site(@cur_site).where(email: item.email, state: 'temporary').first
    end
    if item
      @item = item
      @item.attributes = get_params
    end

    @item.state = 'temporary'
    @item.verification_mail_sent = Time.zone.now
    @item.url_limit = Time.zone.now + 3600
  end

  def send_notify_mail(user, site)
    Gws::Registration::Mailer.notify_mail(user, site, request.protocol, request.host_with_port).deliver_now
  end

  def destroy_registration
    @item = Gws::Registration.site(@cur_site).and_verification_token(params[:token]).and_temporary.first
    raise "404" if @item.blank?
    if @item.url_limit < Time.zone.now
      @item.destroy
      raise "404"
    end
  end

  public

  def new
    @item = @model.new
  end

  # 入力確認
  def confirm
    set_item_for_interim(in_check_email_again: true)
    if Gws::User.where(email: @item.email).present?
      @item.errors.add :email, :in_registerd
      render action: :new
      return
    end
    render action: :new unless @item.valid?
  end

  def interim
    set_item_for_interim

    @group = Gws::Group.site(@cur_site).first
    @sender = @group.sender_email

    # 戻るボタンのクリック
    unless params[:submit]
      render action: :new
      return
    end

    render action: :new unless @item.save
  end

  def verify
    @item = Gws::Registration.site(@cur_site).and_verification_token(params[:token]).and_temporary.first
    raise "404" if @item.blank?
  end

  def registration
    @item = Gws::Registration.site(@cur_site).and_verification_token(params[:token]).and_temporary.first
    raise "404" if @item.blank?

    @item.attributes = get_params
    @item.in_check_password = true
    @item.state = 'request'

    if @item.name.blank?
      @item.errors.add :name, :not_input
    elsif @item.name.length > 40
      @item.errors.add :name, :name_long, count: 40
    end
    if @item.in_password.blank?
      @item.errors.add :in_password, :not_input
    end
    if @item.in_password_again.blank?
      @item.errors.add :in_password_again, :not_input
      render action: :verify
      return
    elsif @item.in_password != @item.in_password_again
      @item.errors.add :password, :mismatch
      render action: :verify
      return
    end

    unless @item.update
      render action: :verify
      return
    end

    user = Gws::User.new
    user.name = @item.name
    user.email = @item.email
    user.password = @item.password
    user.temporary = @item.state
    user.lock_state = 'locked'
    group_ids = []
    if Gws::Group.site(@cur_site).first.default_group.present?
      group_ids << Gws::Group.site(@cur_site).first.default_group.id
    else
      group_ids << @item.site_id
    end
    user.group_ids = group_ids
    if Gws::Group.site(@cur_site).first.default_role_id.present?
      gws_role_ids = []
      gws_role_ids << Gws::Group.site(@cur_site).first.default_role_id
      user.gws_role_ids = gws_role_ids
    end
    user.save
    send_notify_mail(user, @cur_site)
    @item.destroy
  end
end
