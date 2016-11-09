class Cms::AccessRankingJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::AccessRankingTask
  self.task_name = "cms:access_ranking"

  def perform(opt = {})
    opt.symbolize_keys!
    if opt[:purge]
      purge_history(opt[:purge])
    end

    # アクセス履歴は遅れて記録される場合があるので、1分の余裕を見る
    this_time_checked = Time.zone.now - 1.minute

    # 前回チェック時～今回チェックの閲覧履歴を抽出
    criteria = Recommend::History::Log.site(self.site).lte(created: this_time_checked)
    criteria = criteria.gt(created: @task.last_checked) if @task.last_checked.present?
    criteria.each do |log|
      content = log.content
      next if content.blank?
      content = content.becomes_with_route
      # access_count= に応答しない場合、無視
      next if !content.respond_to?(:access_count=)

      # 直近5分間に同じトークン同じページのアクセスがあればカウントしない
      from_time = log.created - 5.minute
      count = Recommend::History::Log.site(self.site)
        .where(token: log.token, target_id: log.target_id, target_class: log.target_class)
        .gt(created: from_time)
        .lt(created: log.created)
        .count

      next if count > 0

      # access_count をインクリメント
      content.inc(access_count: 1)
    end

    # 今回チェック日時を保存
    @task.last_checked = this_time_checked
    @task.save!
    true
  end

  private
    def purge_history(purge)
      time_before = Time.zone.now - eval(purge)

      # 古い履歴を削除
      del_count = Recommend::History::Log.where(site_id: 1, :created.lte => time_before).destroy_all
      puts "deleted #{del_count} histories"

      # 集計結果をクリア
      Cms::Page.where(site_id: 1, :access_count.gt => 0).each { |page| page.set(access_count: 0) }

      # 集計情報をリセット
      Cms::AccessRankingTask.where(site_id: 1, name: 'cms:access_ranking').each { |task| task.set(last_checked: nil) }

      @task.reload
    rescue
    end
end
