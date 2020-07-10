class SS::Migration20200710000000
  include SS::Migration::Base

  depends_on "20200630000000"

  def change
    each_post do |post|
      next if post.post_type.present?

      post.post_type = begin
        if post.text.present? && post.text.strip.present?
          "answer"
        else
          "not_applicable"
        end
      end
      post.state = "public"
      post.group_ids = [ post.user_group_id ]

      if !post.save
        puts post.errors.full_messages.join("\n")
      end
    end
  end

  private

  def each_post(&block)
    criteria = Gws::Monitor::Post.all.unscoped
    criteria = criteria.exists(parent_id: true).exists(post_type: false)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
