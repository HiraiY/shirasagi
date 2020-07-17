class Gws::Affair::LeaveFile
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Affair::Approver
  include Gws::Addon::Affair::LeaveFile
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Affair::Searchable
  include SS::Release

  self.approver_user_class = Gws::User
  self.default_release_state = "closed"

  seqid :id
  field :name, type: String

  permit_params :name

  before_validation :set_name_by_start_end

  validates :name, length: { maximum: 80 }

  # indexing to elasticsearch via companion object
  #around_save ::Gws::Elasticsearch::Indexer::LeaveFileJob.callback
  #around_destroy ::Gws::Elasticsearch::Indexer::LeaveFileJob.callback

  default_scope -> {
    order_by updated: -1
  }

  def private_show_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair_leave_file_path(id: id, site: site, state: 'all')
  end

  def workflow_wizard_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair_leave_wizard_path(site: site.id, id: id)
  end

  def workflow_pages_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair_leave_file_path(site: site.id, id: id, state: "all")
  end

  private

  def set_name_by_start_end
    self.name ||= term_label
  end
end
