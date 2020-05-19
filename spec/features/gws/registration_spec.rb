require 'spec_helper'

describe "gws_registration", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:group) { gws_user.groups.first }
  let(:role) { create(:gws_role_admin) }
  let(:email) { "#{unique_id}@example.jp" }
  let(:sender_email) { "noreply@example.jp" }
  let(:gws_site_path) { gws_site_path(site: site) }
  let(:gws_edit_path) { edit_gws_site_path(site: site) }
  let(:new_path) { new_gws_registration_path(site: site) }
  let(:login_path) { gws_login_path(site: site) }
  let(:logout_path) { gws_logout_path(site: site) }
  let(:main_path) { gws_portal_path(site: site) }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
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

      find("#addon-gws-agents-addons-registration-group_setting").click
      # find("#item_registration_sender_user_id").click
      # puts page.html
      # click_on gws_user.name
      # click_on "グループを選択する"
      # wait_for_cbox do
      #   click_on group.name
      # end
      choose "管理者"
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
      expect(mail.subject).to eq '[仮登録のご案内]'
      expect(mail.body.raw_source).to match(/http(s|):\/\/[\w\-\_\.\!\*\'\)\(]+/)
      puts page.html
    end
  end
end
