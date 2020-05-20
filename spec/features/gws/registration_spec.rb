require 'spec_helper'

describe "gws_registration", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:group) { gws_user.groups.first }
  let(:role) { create(:gws_role_admin) }
  let(:email) { "#{unique_id}@example.jp" }
  let(:name) { unique_id }
  let(:password) { "abc123" }
  let(:sender_email) { "noreply@example.jp" }
  let(:gws_site_path) { gws_site_path(site: site) }
  let(:gws_edit_path) { edit_gws_site_path(site: site) }
  let(:new_path) { new_gws_registration_path(site: site) }
  let(:login_path) { gws_login_path(site: site) }
  let(:logout_path) { gws_logout_path(site: site) }
  let(:main_path) { gws_portal_path(site: site) }
  let(:chars) { (" ".."~").to_a }
  let(:upcases) { ("A".."Z").to_a }
  let(:downcases) { ("a".."z").to_a }
  let(:digits) { ("0".."9").to_a }
  let(:symbols) { chars - upcases - downcases - digits }
  let(:prohibited_chars) { chars.sample(rand(4..6)) }
  let!(:setting) do
    Sys::Setting.create(
      password_min_use: "enabled", password_min_length: rand(16..20),
      password_min_upcase_use: "enabled", password_min_upcase_length: rand(2..4),
      password_min_downcase_use: "enabled", password_min_downcase_length: rand(2..4),
      password_min_digit_use: "enabled", password_min_digit_length: rand(2..4),
      password_min_symbol_use: "enabled", password_min_symbol_length: rand(2..4),
      password_prohibited_char_use: "enabled", password_prohibited_char: prohibited_chars.join,
      password_min_change_char_use: "enabled", password_min_change_char_count: rand(3..5)
    )
  end
  let(:upcase_only_password) { (upcases - prohibited_chars).sample(setting.password_min_length).join }
  let(:downcase_only_password) { (downcases - prohibited_chars).sample(setting.password_min_length).join }
  let(:digit_only_password) { (digits - prohibited_chars).sample(setting.password_min_length).join }
  let(:symbol_only_password) { (symbols - prohibited_chars).sample(setting.password_min_length).join }
  let(:password_contained_prohibited_chars) { prohibited_chars.join }
  let(:password1) do
    etra_length = setting.password_min_length
    - setting.password_min_upcase_length - setting.password_min_downcase_length
    - setting.password_min_digit_length - setting.password_min_symbol_length

    password = ""
    password << (upcases - prohibited_chars).sample(setting.password_min_upcase_length).join
    password << (downcases - prohibited_chars).sample(setting.password_min_downcase_length).join
    password << (digits - prohibited_chars).sample(setting.password_min_digit_length).join
    password << (symbols - prohibited_chars).sample(setting.password_min_symbol_length).join
    password << (chars - prohibited_chars).sample(etra_length).join
    password
  end
  let(:insufficient_password) do
    prev_chars = password1.split("").uniq
    password = ""
    password << prev_chars.sample(setting.password_min_length - setting.password_min_change_char_count + 1).join
    password << (chars - prev_chars - prohibited_chars).sample(setting.password_min_change_char_count - 1).join
    password
  end

  context "new" do
    it do
      visit login_path
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq main_path

      visit gws_edit_path
      expect(current_path).to eq gws_edit_path

      find(".addon-gws-registration-group-setting").click
      # find(".approver_id").click
      # click_on gws_user.name
      # click_on "グループを選択する"
      # wait_for_cbox do
      #   click_on group.name
      # end
      # choose "管理者"
      click_button "保存"

      visit new_path

      within "form" do
        fill_in "item[email]", with: email
        fill_in "item[email_again]", with: email
        click_button "確認画面へ"
      end

      within "form" do
        expect(page.find("input[name='item[email]']", visible: false).value).to eq email
        click_button "戻る"
      end

      within "form" do
        expect(page.find("input[name='item[email]']").value).to eq email
        expect(page.find("input[name='item[email_again]']").value).to eq nil
        fill_in "item[email_again]", with: email
        click_button "確認画面へ"
      end

      within "form" do
        expect(page.find("input[name='item[email]']", visible: false).value).to eq email
        click_button "登録"
      end
      expect(ActionMailer::Base.deliveries.length).to eq 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.from.first).to eq sender_email
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
        puts page.html
      end
      expect(page).to have_content "仮登録の申請をしました。"
      expect(ActionMailer::Base.deliveries.length).to eq 2
      notify_mail = ActionMailer::Base.deliveries.last
      expect(notify_mail.from.first).to eq email
      expect(notify_mail.to.first).to eq sender_email
      expect(notify_mail.subject).to eq "[仮登録申請]#{name} - #{site.name}"
      expect(notify_mail.body.raw_source).to have_content URI.extract(notify_mail.body.raw_source, ["http"]).first
      url = URI.extract(notify_mail.body.raw_source, ["http"]).first
      visit url
      click_on "編集する"

      select "承認", from: "item[temporary]"
    end
  end
end
