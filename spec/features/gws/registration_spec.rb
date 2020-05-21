require 'spec_helper'

describe "gws_registration", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:sys_user) { gws_sys_user }
  let(:group) { gws_user.groups.first }
  let(:email) { "#{unique_id}@example.jp" }
  let(:system_email) { "noreply@example.jp" }
  let(:name) { unique_id }
  let(:password) { "abc123" }
  let(:gws_edit_path) { edit_gws_site_path(site: site) }
  let(:new_path) { new_gws_registration_path(site: site) }
  let(:login_path) { gws_login_path(site: site) }
  let(:main_path) { gws_portal_path(site: site) }
  let(:mypage_path) { sns_mypage_path }
  let(:chars) { (" ".."~").to_a }
  let(:upcases) { ("A".."Z").to_a }
  let(:downcases) { ("a".."z").to_a }
  let(:digits) { ("0".."9").to_a }
  let(:symbols) { chars - upcases - downcases - digits }
  let(:prohibited_chars) { chars.sample(rand(4..6)) }
  let!(:setting) do
    Sys::Setting.create(
      password_min_use: "disabled", password_min_length: rand(16..20),
      password_min_upcase_use: "disabled", password_min_upcase_length: rand(2..4),
      password_min_downcase_use: "disabled", password_min_downcase_length: rand(2..4),
      password_min_digit_use: "disabled", password_min_digit_length: rand(2..4),
      password_min_symbol_use: "disabled", password_min_symbol_length: rand(2..4),
      password_prohibited_char_use: "disabled", password_prohibited_char: prohibited_chars.join,
      password_min_change_char_use: "disabled", password_min_change_char_count: rand(3..5),
      )
  end

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "registration new" do
    before do
      visit login_path
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
    end

    it "approval" do
      visit new_path
      within "form" do
        fill_in "item[email]", with: email
        fill_in "item[email_again]", with: email
        click_button "確認画面へ"
      end

      within "form" do
        expect(page.find("input[name='item[email]']", visible: false).value).to eq email
        click_button "登録"
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.from.first).to eq system_email
      expect(mail.to.first).to eq email
      expect(mail.subject).to eq "[仮登録のご案内]"
      expect(mail.body.raw_source).to have_content URI.extract(mail.body.raw_source, ["http"]).first
      url = URI.extract(mail.body.raw_source, ["http"]).first

      visit url
      within "form" do
        fill_in "item[name]", with: name
        fill_in "item[in_password]", with: password
        fill_in "item[in_password_again]", with: password
        click_button "登録"
      end

      expect(page).to have_content "仮登録の申請をしました。"
      expect(ActionMailer::Base.deliveries.length).to eq 2
      notify_mail = ActionMailer::Base.deliveries.last
      expect(notify_mail.from.first).to eq system_email
      expect(notify_mail.to.first).to eq system_email
      expect(notify_mail.subject).to eq "[仮登録申請]#{name} - #{site.name}"
      expect(notify_mail.body.raw_source).to have_content URI.extract(notify_mail.body.raw_source, ["http"]).first
      url = URI.extract(notify_mail.body.raw_source, ["http"]).first

      visit url
      expect(page).to have_content name
      expect(page).to have_content email
      expect(page).to have_content "利用停止"
      expect(page).to have_content "承認待ち"

      click_on "編集する"
      select "承認", from: "item[temporary]"
      find(".send").click_on I18n.t('ss.buttons.save')
      expect(page).to have_content "利用可"
      expect(page).to have_content "承認"

      expect(ActionMailer::Base.deliveries.length).to eq 3
      approval_mail = ActionMailer::Base.deliveries.last
      expect(approval_mail.from.first).to eq system_email
      expect(approval_mail.to.first).to eq email
      expect(approval_mail.subject).to eq "[仮登録の承認]"
      expect(approval_mail.body.raw_source).to have_content URI.extract(approval_mail.body.raw_source, ["http"]).first
      url = URI.extract(approval_mail.body.raw_source, ["http"]).first

      visit url
      fill_in "item[email]", with: email
      fill_in "item[password]", with: password
      click_button I18n.t("ss.login")
      expect(current_path).to eq mypage_path
    end

    it "deny" do
      visit new_path
      within "form" do
        fill_in "item[email]", with: email
        fill_in "item[email_again]", with: email
        click_button "確認画面へ"
      end

      within "form" do
        expect(page.find("input[name='item[email]']", visible: false).value).to eq email
        click_button "登録"
      end

      mail = ActionMailer::Base.deliveries.first
      url = URI.extract(mail.body.raw_source, ["http"]).first

      visit url
      within "form" do
        fill_in "item[name]", with: name
        fill_in "item[in_password]", with: password
        fill_in "item[in_password_again]", with: password
        click_button "登録"
      end

      notify_mail = ActionMailer::Base.deliveries.last
      url = URI.extract(notify_mail.body.raw_source, ["http"]).first

      visit url
      click_on "編集する"
      select "非承認", from: "item[temporary]"
      find(".send").click_on I18n.t('ss.buttons.save')
      expect(page).to have_content "利用停止"
      expect(page).to have_content "非承認"

      expect(ActionMailer::Base.deliveries.length).to eq 3
      approval_mail = ActionMailer::Base.deliveries.last
      expect(approval_mail.from.first).to eq system_email
      expect(approval_mail.to.first).to eq email
      expect(approval_mail.subject).to eq "[仮登録の非承認]"

      visit login_path

      fill_in "item[email]", with: email
      fill_in "item[password]", with: password
      click_button I18n.t("ss.login")
      expect(current_path).not_to eq mypage_path
    end
  end

  context "registration setting" do
    before do
      visit login_path
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
    end

    it do
      visit gws_edit_path
      expect(current_path).to eq gws_edit_path

      find("#addon-gws-agents-addons-system-group_setting").click
      find(".addon-gws-system-group-setting").click_on "ユーザーを選択する"
      click_on "gws-sys (sys)"

      find("#addon-gws-agents-addons-registration-group_setting").click
      find(".approver").click_on "ユーザーを選択する"

      click_on "gw-admin (admin)"
      find(".gws-default_group").click_on "グループを選択する"
      click_on "企画政策部"

      check "管理者"
      find(".send").click_on I18n.t('ss.buttons.save')

      find("#addon-gws-agents-addons-system-group_setting").click
      expect(page).to have_content "gws-sys (sys)"

      find("#addon-gws-agents-addons-registration-group_setting").click
      expect(page).to have_content "gw-admin (admin)"
      expect(page).to have_content "企画政策部"
      expect(page).to have_content "管理者"

      visit new_path
      within "form" do
        fill_in "item[email]", with: email
        fill_in "item[email_again]", with: email
        click_button "確認画面へ"
      end

      within "form" do
        expect(page.find("input[name='item[email]']", visible: false).value).to eq email
        click_button "登録"
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.from.first).to eq sys_user.email
      expect(mail.to.first).to eq email
      expect(mail.subject).to eq "[仮登録のご案内]"
      expect(mail.body.raw_source).to have_content URI.extract(mail.body.raw_source, ["http"]).first
      url = URI.extract(mail.body.raw_source, ["http"]).first

      visit url
      within "form" do
        fill_in "item[name]", with: name
        fill_in "item[in_password]", with: password
        fill_in "item[in_password_again]", with: password
        click_button "登録"
      end

      expect(page).to have_content "仮登録の申請をしました。"
      expect(ActionMailer::Base.deliveries.length).to eq 2
      notify_mail = ActionMailer::Base.deliveries.last
      expect(notify_mail.from.first).to eq sys_user.email
      expect(notify_mail.to.first).to eq user.email
      expect(notify_mail.subject).to eq "[仮登録申請]#{name} - #{site.name}"
      expect(notify_mail.body.raw_source).to have_content URI.extract(notify_mail.body.raw_source, ["http"]).first
      url = URI.extract(notify_mail.body.raw_source, ["http"]).first

      visit url
      expect(page).to have_content name
      expect(page).to have_content email
      expect(page).to have_content "利用停止"
      expect(page).to have_content "承認待ち"
      expect(page).to have_content "シラサギ市/企画政策部"
      expect(page).to have_content "管理者"
    end
  end

  context "url expiration_date" do
    it "access after 1 hour" do
      visit new_path
      within "form" do
        fill_in "item[email]", with: email
        fill_in "item[email_again]", with: email
        click_button "確認画面へ"
      end

      within "form" do
        expect(page.find("input[name='item[email]']", visible: false).value).to eq email
        click_button "登録"
      end

      mail = ActionMailer::Base.deliveries.first
      url = URI.extract(mail.body.raw_source, ["http"]).first

      travel_to(Time.zone.now + 3601) do
        visit url
        expect(page).to have_content "お探しのページは見つかりません"
      end
    end
  end

  context "re register email address" do
    it "fail first email url" do
      visit new_path
      within "form" do
        fill_in "item[email]", with: email
        fill_in "item[email_again]", with: email
        click_button "確認画面へ"
      end

      within "form" do
        expect(page.find("input[name='item[email]']", visible: false).value).to eq email
        click_button "登録"
      end

      visit new_path
      within "form" do
        fill_in "item[email]", with: email
        fill_in "item[email_again]", with: email
        click_button "確認画面へ"
      end

      within "form" do
        expect(page.find("input[name='item[email]']", visible: false).value).to eq email
        click_button "登録"
      end

      expect(ActionMailer::Base.deliveries.length).to eq 2
      first_mail = ActionMailer::Base.deliveries.first
      first_url = URI.extract(first_mail.body.raw_source, ["http"]).first
      visit first_url
      expect(page).to have_content "お探しのページは見つかりません"

      second_mail = ActionMailer::Base.deliveries.last
      second_url = URI.extract(second_mail.body.raw_source, ["http"]).first
      visit second_url
      within "form" do
        fill_in "item[name]", with: name
        fill_in "item[in_password]", with: password
        fill_in "item[in_password_again]", with: password
        click_button "登録"
      end
      expect(page).to have_content "仮登録の申請をしました。"
    end
  end
end