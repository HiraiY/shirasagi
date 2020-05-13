class Gws::Registration::Mailer < ActionMailer::Base
  # 仮登録の通知メールを送る
  def notify_mail(user, protocol, host)
    @user = user

    sender = "a"

    mail from: sender, to: user.email
  end

  # 仮登録ページへの案内メールを送る
  def verification_mail(user, protocol, host)
    @user = user
    @page_url = Rails.application.routes.url_helpers.gws_registration_index_url(protocol: protocol, host: host, site: user.site_id)
    sender = "a"

    mail from: sender, to: user.email
  end

  # 承認メールを送る
  def approval_mail(user)
    @user = user
    sender = "a"

    mail from: sender, to: user.email
  end

  # 非承認メールを送る
  def deny_mail(user)
    @user = user
    sender = "a"

    mail from: sender, to: user.email
  end

  # パスワードの再設定メールを配信する。
  def reset_password_mail(member)
    @member = member
    sender = "#{@node.sender_name} <#{@node.sender_email}>"

    mail from: sender, to: member.email
  end
end
