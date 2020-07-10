FactoryBot.define do
  factory :gws_monitor_post, class: Gws::Monitor::Post do
    cur_site { gws_site }
    cur_user { gws_user }

    post_type "answer"
    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }
    state "public"
    group_ids { cur_user.group_ids }
  end
end
