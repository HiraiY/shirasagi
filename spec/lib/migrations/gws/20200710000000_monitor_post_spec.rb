require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20200710000000_monitor_post.rb")

RSpec.describe SS::Migration20200710000000, dbscope: :example do
  let!(:topic) do
    create(
      :gws_monitor_topic,
      attend_group_ids: gws_user.group_ids, state: "public", article_state: "open", spec_config: "my_group"
    )
  end
  let!(:post1) { create :gws_monitor_post, topic: topic, parent: topic, post_type: nil }
  let!(:post2) { create :gws_monitor_post, topic: topic, parent: topic, post_type: nil, text: nil }

  before do
    post1.unset(:post_type, :state, :group_ids)
    post2.unset(:post_type, :state, :group_ids)

    described_class.new.change
  end

  it do
    post1.reload
    expect(post1.post_type).to eq "answer"
    expect(post1.state).to eq "public"
    expect(post1.groups.count).to eq 1
    expect(post1.groups.first.id).to eq post1.user_group_id

    post2.reload
    expect(post2.post_type).to eq "not_applicable"
    expect(post2.state).to eq "public"
    expect(post2.groups.count).to eq 1
    expect(post2.groups.first.id).to eq post2.user_group_id
  end
end
