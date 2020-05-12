class Gws::Registration::Mailer < ActionMailer::Base
  def notify_mail(member)
    @member = member

    sender = "a"

    mail from: sender, to: member.email
  end

  # 会員登録に対して確認メールを配信する。
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
