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
  let(:reset_password_path) { reset_password_gws_registration_index_path(site: site) }
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

  context "reset password" do
    it do
      visit reset_password_path
      within "form" do
        fill_in "item[email]", with: user.email
        click_button "送信する"
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.from.first).to eq system_email
      expect(mail.to.first).to eq user.email
      expect(mail.subject).to eq "[パスワード再設定のご案内]"
      expect(mail.body.raw_source).to have_content URI.extract(mail.body.raw_source, ["http"]).first
      url = URI.extract(mail.body.raw_source, ["http"]).first

      visit url
      within "form" do
        fill_in "item[new_password]", with: password
        fill_in "item[new_password_again]", with: password
        click_button "パスワードを変更"
      end
      expect(page).to have_content "パスワードを変更しました。"

      click_on "ログイン"

      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      expect(page).to have_content "ログインできませんでした。"

      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: password
        click_button I18n.t("ss.login")
      end

      expect(current_path).to eq mypage_path
    end
  end

  context "url expiration_date" do
    it "access after 1 hour" do
      visit reset_password_path
      within "form" do
        fill_in "item[email]", with: user.email
        click_button "送信する"
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.from.first).to eq system_email
      expect(mail.to.first).to eq user.email
      expect(mail.subject).to eq "[パスワード再設定のご案内]"
      expect(mail.body.raw_source).to have_content URI.extract(mail.body.raw_source, ["http"]).first
      url = URI.extract(mail.body.raw_source, ["http"]).first

      travel_to(Time.zone.now + 3601) do
        visit url
        expect(page).to have_content "お探しのページは見つかりません"
      end
    end
  end

  context "re register email address" do
    it "fail first email url" do
      visit reset_password_path
      within "form" do
        fill_in "item[email]", with: user.email
        click_button "送信する"
      end

      visit reset_password_path
      within "form" do
        fill_in "item[email]", with: user.email
        click_button "送信する"
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
        fill_in "item[new_password]", with: password
        fill_in "item[new_password_again]", with: password
        click_button "パスワードを変更"
      end
      expect(page).to have_content "パスワードを変更しました。"
    end
  end
end