require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) do
    create :article_node_page, filename: "docs", name: "article", group_ids: [cms_group.id], st_form_ids: [form.id]
  end
  let!(:item) { create :article_page, cur_node: node, group_ids: [cms_group.id] }
  let!(:edit_path) { edit_article_page_path site.id, node, item }

  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: [cms_group.id]) }
  let!(:column1) { create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", order: 1) }
  let!(:column2) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 2) }

  let!(:permissions) { Cms::Role.permission_names.select { |item| item =~ /_private_/ } }
  let!(:role) { create :cms_role, name: "role", permissions: permissions, permission_level: 3, cur_site: site }
  let(:user2) { create :cms_user, uid: unique_id, name: unique_id, group_ids: [cms_group.id], cms_role_ids: [role.id] }

  context "attach file from upload" do
    before { login_cms_user }

    it "#edit" do
      visit edit_path

      addon = first("#addon-cms-agents-addons-file")
      addon.find('.toggle-head').click if addon.matches_css?(".body-closed")

      within "#addon-cms-agents-addons-file" do
        click_on I18n.t("ss.buttons.upload")
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        wait_for_ajax

        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        click_button I18n.t("ss.buttons.attach")
        wait_for_ajax
      end

      within '#selected-files' do
        expect(page).to have_no_css('.name', text: 'keyvisual.jpg')
        expect(page).to have_css('.name', text: 'keyvisual.gif')
      end
    end

    it "#edit file name" do
      visit edit_path
      within "form#item-form" do
        within "#addon-cms-agents-addons-file" do
          click_on I18n.t("ss.buttons.upload")
        end
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        wait_for_ajax

        click_on I18n.t("ss.buttons.edit")
        fill_in "item[name]", with: "modify.jpg"
        click_button I18n.t("ss.buttons.save")
        wait_for_ajax

        click_on "modify.jpg"
      end

      within '#selected-files' do
        expect(page).to have_css('.name', text: 'modify.jpg')
      end
    end
  end

  context "attach file from user file" do
    before { login_cms_user }

    it do
      visit edit_path
      within "form#item-form" do
        within "#addon-cms-agents-addons-file" do
          click_on I18n.t("sns.user_file")
        end
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        wait_for_ajax

        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        click_button I18n.t("ss.buttons.attach")
        wait_for_ajax
      end

      within "form#item-form" do
        within '#selected-files' do
          expect(page).to have_no_css('.name', text: 'keyvisual.jpg')
          expect(page).to have_css('.name', text: 'keyvisual.gif')
        end
        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.file_ids.length).to eq 1
      attached_file = item.files.first
      # owner item
      expect(attached_file.owner_item_type).to eq item.class.name
      expect(attached_file.owner_item_id).to eq item.id
      # other
      expect(attached_file.user_id).to eq cms_user.id
    end
  end

  context "attach file from cms file" do
    context "with cms addon file" do
      context "when file is attached / saved on the modal dialog" do
        it do
          login_user(user2)

          visit edit_path
          within "form#item-form" do
            within "#addon-cms-agents-addons-file" do
              click_on I18n.t("cms.file")
            end
          end

          wait_for_cbox do
            attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
            click_button I18n.t("ss.buttons.save")
            wait_for_ajax

            attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
            click_button I18n.t("ss.buttons.attach")
            wait_for_ajax
          end

          within "form#item-form" do
            within '#selected-files' do
              expect(page).to have_no_css('.name', text: 'keyvisual.jpg')
              expect(page).to have_css('.name', text: 'keyvisual.gif')
            end

            click_on I18n.t("ss.buttons.publish_save")
          end
          wait_for_notice I18n.t('ss.notice.saved')

          item.reload
          expect(item.file_ids.length).to eq 1
          attached_file = item.files.first
          # owner item
          expect(attached_file.owner_item_type).to eq item.class.name
          expect(attached_file.owner_item_id).to eq item.id
          # other
          expect(attached_file.user_id).to eq user2.id
        end
      end

      context "when a file uploaded by other user is attached" do
        let(:file_name) { "#{unique_id}.jpg" }
        let!(:file) do
          # cms/file is created by cms_user
          tmp_ss_file(
            Cms::File,
            site: site, user: cms_user, model: "cms/file", basename: file_name,
            contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg",
            group_ids: cms_user.group_ids
          )
        end

        it do
          login_user(user2)
          visit edit_path
          within "form#item-form" do
            within "#addon-cms-agents-addons-file" do
              click_on I18n.t("cms.file")
            end
          end

          wait_for_cbox do
            click_on file_name
          end

          within "form#item-form" do
            within "#addon-cms-agents-addons-file" do
              within ".file-view" do
                click_on I18n.t("sns.file_attach")
                click_on I18n.t("sns.image_paste")
                click_on I18n.t("sns.thumb_paste")
              end
            end

            click_on I18n.t("ss.buttons.publish_save")
          end
          click_on I18n.t("ss.buttons.ignore_alert")
          wait_for_notice I18n.t('ss.notice.saved')

          item.reload
          expect(item.file_ids.length).to eq 1

          file.reload
          attached_file = item.files.first
          # copy is attacched
          expect(attached_file.id).not_to eq file.id
          expect(attached_file.name).to eq file_name
          expect(attached_file.filename).to eq file.filename
          expect(attached_file.size).to eq file.size
          expect(attached_file.content_type).to eq file.content_type
          # owner item
          expect(attached_file.owner_item_type).to eq item.class.name
          expect(attached_file.owner_item_id).to eq item.id
          # other
          expect(attached_file.user_id).to eq user2.id
        end
      end
    end

    context "with entry form" do
      it "#edit" do
        login_user(user2)

        visit edit_path

        within 'form#item-form' do
          select form.name, from: 'item[form_id]'
          find('.btn-form-change').click
        end

        within ".column-value-palette" do
          click_on column1.name
        end
        within ".column-value-cms-column-fileupload" do
          click_on I18n.t("cms.file")
        end
        wait_for_cbox do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          click_button I18n.t("ss.buttons.save")
          wait_for_ajax

          attach_file 'item[in_files][]', "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
          click_on I18n.t('ss.buttons.attach')
          wait_for_ajax
        end
        within "form#item-form" do
          within ".column-value-cms-column-fileupload" do
            expect(page).to have_no_css('.column-value-files', text: 'keyvisual.jpg')
            expect(page).to have_css('.column-value-files', text: 'keyvisual.gif')
          end
        end

        within ".column-value-palette" do
          click_on column2.name
        end
        within ".column-value-cms-column-free" do
          click_on I18n.t("cms.file")
        end
        wait_for_cbox do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          click_button I18n.t("ss.buttons.save")
          wait_for_ajax

          attach_file 'item[in_files][]', "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
          click_on I18n.t('ss.buttons.attach')
          wait_for_ajax
        end
        within "form#item-form" do
          within ".column-value-cms-column-free" do
            expect(page).to have_no_css('.column-value-files', text: 'keyvisual.jpg')
            expect(page).to have_css('.column-value-files', text: 'keyvisual.gif')
          end

          click_on I18n.t("ss.buttons.publish_save")
        end
        click_on I18n.t("ss.buttons.ignore_alert")
        wait_for_notice I18n.t('ss.notice.saved')

        item.reload

        attached_file1 = item.column_values.where(column_id: column1.id).first.file
        # owner item
        expect(attached_file1.owner_item_type).to eq item.class.name
        expect(attached_file1.owner_item_id).to eq item.id
        # other
        expect(attached_file1.user_id).to eq user2.id

        attached_file2 = item.column_values.where(column_id: column2.id).first.files.first
        # owner item
        expect(attached_file2.owner_item_type).to eq item.class.name
        expect(attached_file2.owner_item_id).to eq item.id
        # other
        expect(attached_file2.user_id).to eq user2.id
      end
    end
  end
end