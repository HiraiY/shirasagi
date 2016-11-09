class Cms::AccessRankingsController < ApplicationController
  include Cms::BaseFilter
  include SS::JobFilter

  model Recommend::History::Log
  navi_view "recommend/main/navi"

  private
    def job_class
      Cms::AccessRankingJob
    end

    def job_bindings
      {
        site_id: @cur_site.id,
      }
    end

    def task_name
      job_class.task_name
    end

    def set_item
      @item = Cms::AccessRankingTask.find_or_create_by name: task_name, site_id: @cur_site.id
    end
end
