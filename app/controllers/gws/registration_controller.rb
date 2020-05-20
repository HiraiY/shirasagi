class Gws::RegistrationController < ApplicationController
  include Gws::BaseFilter
  include Sns::LoginFilter

  skip_before_action :logged_in?

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
  end

  def send_notify_mail(user, site)
    Gws::Registration::Mailer.notify_mail(user, site, request.protocol, request.host_with_port).deliver_now
  end

  def send_user_password_mail(user, site)
    Gws::Registration::Mailer.user_password_mail(user, site).deliver_now
  end

  def send_admin_password_mail(user, site)
    Gws::Registration::Mailer.admin_password_mail(user, site).deliver_now
  end

  def create_token(item)
    item.token = SecureRandom.urlsafe_base64(12)
    item.expiration_date = 60.minutes.from_now
  end

  def token_disabled?(item)
    return false if item.try(:expiration_date).blank?
    return item.expiration_date < Time.zone.now
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
    create_token(@item)

    @group = Gws::Group.site(@cur_site).first
    @sender = @group.set_sender_email

    # 戻るボタンのクリック
    unless params[:submit]
      render action: :new
      return
    end

    render action: :new unless @item.save
  end

  def verify
    @item = Gws::Registration.site(@cur_site).and_token(params[:token]).and_temporary.first
    raise "404" if @item.blank? || token_disabled?(@item)
  end

  def registration
    @item = Gws::Registration.site(@cur_site).and_token(params[:token]).and_temporary.first
    raise "404" if @item.blank? || token_disabled?(@item)

    @item.attributes = get_params
    @item.in_check_name = true
    @item.in_check_password = true
    @item.state = 'request'

    if @item.name.blank?
      @item.errors.add :name, :not_input
    elsif @item.name.length > 40
      @item.errors.add :name, :name_long, count: 40
    end

    if @item.errors.present?
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
    if Gws::Group.site(@cur_site).first.default_role_ids.present?
      user.gws_role_ids = Gws::Group.site(@cur_site).first.default_role_ids
    end
    user.save
    send_notify_mail(user, @cur_site)
    @item.destroy
  end

  # パスワード再設定
  def reset_password
    @item = Gws::Registration.new
    return if request.get?

    @item = @model.new get_params

    if @item.email.blank?
      @item.errors.add :email, :not_input
      render action: :reset_password
      return
    end

    user = Gws::User.site(@cur_site).and_enabled.where(email: @item.email).first
    if user.nil?
      @item.errors.add :email, :not_registerd
      render action: :reset_password
      return
    end
    user.cur_site = @cur_site
    group = Gws::Group.site(@cur_site).first
    sender = group.set_sender_email
    user_email = user.email
    create_token(user)
    user.save

    Gws::Registration::Mailer.reset_password_mail(user, request.protocol, request.host_with_port).deliver_now

    redirect_to confirm_reset_password_gws_registration_index_path(sender: sender, user_email: user_email)
  end

  def confirm_reset_password
  end

  def change_password
    @item = Gws::User.site(@cur_site).and_enabled.and_token(params[:token]).first rescue nil
    raise "404" unless @item.present? || token_disabled?(@item)

    return if request.get?

    @item.in_password = params[:item][:new_password]

    if @item.in_password.blank?
      @item.errors.add :in_password, :not_input
    elsif @item.in_password != params[:item][:new_password_again]
      @item.errors.add :in_password, :mismatch
    end

    if @item.errors.present?
      render action: :change_password
      return
    end

    @item.encrypt_password
    @item.token = nil
    @item.expiration_date = nil

    unless @item.update
      render :change_password
      return
    end

    send_user_password_mail(@item, @cur_site)
    send_admin_password_mail(@item, @cur_site)

    redirect_to confirm_password_gws_registration_index_path
  end

  def confirm_password
  end
end
