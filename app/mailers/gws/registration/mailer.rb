class Gws::Registration::Mailer < ActionMailer::Base

  def url_helpers
    Rails.application.routes.url_helpers
  end

  # 仮登録の通知メールを送る
  def notify_mail(user, site, protocol, host)
    require 'pry'
    binding.pry
    @user = user

    @page_url = url_helpers.gws_user_url(protocol: protocol, host: host, site: site.id, id: user.id)
    sender = "a"

    mail from: sender, to: user.email
  end

  # 仮登録ページへの案内メールを送る
  def verification_mail(user, protocol, host)
    require 'pry'
    binding.pry
    @user = user
    @page_url = url_helpers.gws_registration_index_url(protocol: protocol, host: host, site: user.site_id)
    sender = "a"

    mail from: sender, to: user.email
  end

  # 承認メールを送る
  def approval_mail(user, protocol, host)
    @user = user
    @page_url = url_helpers.sns_login_url(protocol: protocol, host: host)
    require 'pry'
    binding.pry
    sender = "a"

    mail from: sender, to: user.email
  end

  # 非承認メールを送る
  def deny_mail(user)
    @user = user
    sender = "a"

    mail from: sender, to: user.email
  end
end
