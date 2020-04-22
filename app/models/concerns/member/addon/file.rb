module Member::Addon
  module File
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :files, class_name: "SS::File"
      permit_params file_ids: []

      before_save :save_files
      after_save :put_contains_urls_logs
      after_destroy :destroy_files

      #after_save :generate_public_files, if: ->{ public? }
      #after_save :remove_public_files, if: ->{ !public? }
    end

    def allow_other_user_files
      @allowed_other_user_files = true
    end

    def allowed_other_user_files?
      @allowed_other_user_files == true
    end

    def save_files
      add_ids = file_ids - file_ids_was.to_a

      ids = []
      files.each do |file|
        if !add_ids.include?(file.id)
          file.update(owner_item: self, state: state) if state_changed?
        elsif !allowed_other_user_files? && @cur_user && @cur_user.id != file.user_id
          next
        else
          file.update(site_id: site_id, model: model_name.i18n_key, owner_item: self, state: state)
          item = create_history_log(file)
          item.action = "update"
          item.behavior = "attachment"
          item.save
        end
        ids << file.id
      end
      self.file_ids = ids

      del_ids = file_ids_was.to_a - ids
      del_ids.each do |id|
        file = SS::File.where(id: id).first
        file.destroy if file
        item = create_history_log(file)
        item.action = "destroy"
        item.behavior = "attachment"
        item.save
      end
    end

    def destroy_files
      files.destroy_all
    end

    def generate_public_files
      files.each do |file|
        file.generate_public_file
      end
    end

    def remove_public_files
      files.each do |file|
        file.remove_public_file
      end
    end

    def create_history_log(file)
      History::Log.new(
        site_id: site.id,
        user_id: user.id,
        session_id: Rails.application.current_session_id,
        request_id: Rails.application.current_request_id,
        controller: self.model_name.i18n_key,
        url: file.try(:url),
        page_url: Rails.application.current_path_info
      )
    end

    def put_contains_urls_logs
      add_contains_urls = self.contains_urls - self.contains_urls_was.to_a
      add_contains_urls.each do |file|
        item = create_history_log(file)
        item.url = file
        item.action = "update"
        item.behavior = "paste"
        item.save
      end

      del_contains_urls = self.contains_urls_was.to_a - self.contains_urls
      del_contains_urls.each do |file|
        item = create_history_log(file)
        item.url = file
        item.action = "destroy"
        item.behavior = "paste"
        item.save
      end
    end
  end
end
