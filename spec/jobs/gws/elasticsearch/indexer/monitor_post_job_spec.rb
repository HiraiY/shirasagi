require 'spec_helper'

describe Gws::Elasticsearch::Indexer::MonitorPostJob, dbscope: :example do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }
  let(:file_path) { Rails.root.join('spec', 'fixtures', 'ss', 'logo.png') }
  let(:es_host) { "#{unique_id}.example.jp" }
  let(:es_url) { "http://#{es_host}" }
  let(:file) { tmp_ss_file(user: user, contents: File.binread(file_path), binary: true, content_type: 'image/png') }
  let(:category) { create(:gws_monitor_category, cur_site: site) }
  let(:requests) { [] }
  let!(:topic) do
    create(
      :gws_monitor_topic, cur_site: site, cur_user: user, attend_group_ids: user.group_ids,
      category_ids: [category.id]
    )
  end

  before do
    # enable elastic search
    site.menu_elasticsearch_state = 'show'
    site.elasticsearch_hosts = es_url
    site.save!
  end

  before do
    stub_request(:any, /#{::Regexp.escape(es_host)}/).to_return do |request|
      # examine request later
      requests << request.as_json.dup
      { body: '{}', status: 200, headers: { 'Content-Type' => 'application/json; charset=UTF-8' } }
    end
  end

  after do
    WebMock.reset!
  end

  describe '.callback' do
    context 'when model was created' do
      it do
        post = nil
        perform_enqueued_jobs do
          expectation = expect do
            post = create(
              :gws_monitor_post, cur_site: site, cur_user: user, topic_id: topic.id, parent_id: topic.id,
              post_type: "answer", text: unique_id, file_ids: [file.id],
              state: "draft", group_ids: user.group_ids
            )
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.all.each do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 2
        requests.first.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/post-#{post.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/monitor/-/topics/#{topic.id}#post-#{post.id}"
          expect(body['name']).to eq post.name
          expect(body['mode']).to eq topic.mode
          expect(body['text']).to eq post.text
          expect(body['categories']).to include(*topic.categories.pluck(:name))
          expect(body['release_date']).to be_blank
          expect(body['close_date']).to be_blank
          expect(body['released']).to be_blank
          expect(body['state']).to eq "closed"
          expect(body['user_name']).to eq post.user_long_name
          expect(body['group_ids']).to include(*post.groups.pluck(:id))
          expect(body['custom_group_ids']).to be_blank
          expect(body['user_ids']).to be_blank
          expect(body['permission_level']).to eq 1
          expect(body['readable_group_ids']).to include(*topic.attend_groups.pluck(:id))
          expect(body['updated']).to eq post.updated.iso8601
          expect(body['created']).to eq post.created.iso8601
        end
        requests.second.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/file-#{file.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/monitor/-/topics/#{topic.id}#file-#{file.id}"
        end
      end
    end

    context 'when post was approved' do
      let!(:post) do
        create(
          :gws_monitor_post, cur_site: site, cur_user: user, topic_id: topic.id, parent_id: topic.id,
          post_type: "answer", text: unique_id, file_ids: [file.id],
          state: "draft", group_ids: user.group_ids
        )
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            post.state = "approve"
            post.save!
          end
          # 回答を承認すると、照会の回答状態が変更されるため、照会のインデクサーも実行される。これが観測されるため、実行ジョブ数は 2 となる。
          expectation.to change { performed_jobs.size }.by(2)
        end

        expect(Gws::Job::Log.count).to eq 2
        Gws::Job::Log.all.each do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 3
        requests.first.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/post-#{post.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/monitor/-/topics/#{topic.id}#post-#{post.id}"
          expect(body['state']).to eq "public"
        end
        requests.second.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/file-#{file.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/monitor/-/topics/#{topic.id}#file-#{file.id}"
        end
        # 回答を承認すると、照会の回答状態が変更されるため、照会のインデクサーも実行される。これが 3 つめとして観測される。
        requests.third.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/post-#{topic.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/monitor/-/topics/#{topic.id}#post-#{topic.id}"
        end
      end
    end

    context 'when post was updated' do
      let!(:post) do
        create(
          :gws_monitor_post, cur_site: site, cur_user: user, topic_id: topic.id, parent_id: topic.id,
          post_type: "answer", text: unique_id, file_ids: [file.id],
          state: "public", group_ids: user.group_ids
        )
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            post.text = unique_id
            post.file_ids = []
            post.save!
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 2
        requests.first.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/post-#{post.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/monitor/-/topics/#{topic.id}#post-#{post.id}"
        end
        # file was removed from post
        requests.second.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/file-#{file.id}")
        end
      end
    end

    context 'when post was depublished' do
      let!(:post) do
        create(
          :gws_monitor_post, cur_site: site, cur_user: user, topic_id: topic.id, parent_id: topic.id,
          post_type: "answer", text: unique_id, file_ids: [file.id],
          state: "public", group_ids: user.group_ids
        )
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            post.state = "closed"
            post.save!
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 2
        requests.first.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/post-#{post.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/monitor/-/topics/#{topic.id}#post-#{post.id}"
          expect(body['state']).to eq "closed"
        end
        requests.second.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/file-#{file.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/monitor/-/topics/#{topic.id}#file-#{file.id}"
        end
      end
    end

    context 'when post was destroyed' do
      let!(:post) do
        create(
          :gws_monitor_post, cur_site: site, cur_user: user, topic_id: topic.id, parent_id: topic.id,
          post_type: "answer", text: unique_id, file_ids: [file.id],
          state: "public", group_ids: user.group_ids
        )
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            post.destroy
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 2
        requests.first.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/post-#{post.id}")
        end
        requests.second.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/file-#{file.id}")
        end
      end
    end
  end
end
