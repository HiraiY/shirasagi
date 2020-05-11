class Gws::RegistrationController < ApplicationController
  include Gws::BaseFilter
  include Sns::LoginFilter

  skip_before_action :logged_in?

  model Gws::Registration

  private

  def fix_params
    { cur_site: @cur_site, in_protocol: request.protocol, in_host: request.host }
  end

  def permit_fields
    @model.permitted_fields
  end

  def get_params
    params.require(:item).permit(permit_fields).merge(fix_params)
  end

  def set_item_for_register(extra_attrs = {})
    @item = item = @model.new get_params.merge(extra_attrs)
    if item.email.present?
      item = @model.site(@cur_site).where(email: item.email).first
    end
    if item
      @item = item
      @item.attributes = get_params
    end
    @item
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
    @item
  end

  public

  def new
    @item = @model.new
  end

  # 入力確認
  def confirm
    set_item_for_interim(in_check_email_again: true)
    render action: :new unless @item.valid?
  end

  def interim
    set_item_for_interim

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

  private

end
