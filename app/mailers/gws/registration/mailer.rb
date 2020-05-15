class Gws::Registration::Mailer < ActionMailer::Base

  def url_helpers
    Rails.application.routes.url_helpers
  end

  # 仮登録ページへの案内メールを送る
  def verification_mail(user, protocol, host)
    @user = user
    @page_url = url_helpers.gws_registration_index_url(protocol: protocol, host: host, site: user.site_id)
    @group = Gws::Group.where(_id: user.site_id).first
    sender = @group.registration_sender_address

    mail from: sender, to: user.email
  end

  # 仮登録の通知メールを送る
  def notify_mail(user, site, protocol, host)
    @user = user
    @site = site
    @page_url = url_helpers.gws_user_url(protocol: protocol, host: host, site: site.id, id: user.id)
    sender = "#{@user.name} <#{@user.email}>"
    @group = Gws::Group.where(_id: site.id).first
    @receiver = @group.registration_receiver_address

    mail from: sender, to: @receiver
  end

  # 承認メールを送る
  def approval_mail(user, site, protocol, host)
    @user = user
    @page_url = url_helpers.sns_login_url(protocol: protocol, host: host)
    @group = Gws::Group.where(_id: site.id).first
    sender = @group.registration_sender_address

    mail from: sender, to: user.email
  end

  # 非承認メールを送る
  def deny_mail(user, site)
    @user = user
    @group = Gws::Group.where(_id: site.id).first
    sender = @group.registration_sender_address

    mail from: sender, to: user.email
  end

  # パスワードの再設定メールを配信する。
  def reset_password_mail(user, protocol, host)
    @user = user
    @page_url = url_helpers.change_password_gws_registration_index_url(protocol: protocol, host: host, site: user.cur_site.id)
    @group = Gws::Group.site(user.cur_site).first
    sender = @group.registration_sender_address

    mail from: sender, to: user.email
  end
end
