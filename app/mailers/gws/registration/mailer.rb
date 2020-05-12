class Gws::Registration::Mailer < ActionMailer::Base
  # 仮登録の通知メールを送る
  def notify_mail(member, protocol, host)
    @member = member

    sender = "a"

    mail from: sender, to: member.email
  end

  # 仮登録ページへの案内メールを送る
  def verification_mail(member, protocol, host)
    @member = member
    @page_url = Rails.application.routes.url_helpers.gws_registration_index_url(protocol: protocol, host: host, site: member.site_id)
    sender = "a"

    mail from: sender, to: member.email
  end

  # パスワードの再設定メールを配信する。
  def reset_password_mail(member)
    @member = member
    sender = "#{@node.sender_name} <#{@node.sender_email}>"

    mail from: sender, to: member.email
  end
end
