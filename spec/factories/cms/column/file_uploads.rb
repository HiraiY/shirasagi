FactoryBot.define do
  factory :cms_column_file_upload, class: Cms::Column::FileUpload do
    cur_site { cms_site }

    name { "name-#{unique_id}" }
    order { rand(999) }
    required { %w(required optional).sample }
    tooltips { "tooltips-#{unique_id}" }
    prefix_label { "prefix_label-#{unique_id}" }
    postfix_label { "postfix_label-#{unique_id}" }
    file_type { %w(image video attachment banner).sample }
    html_tag { %w(a+img a img).sample }
  end
end
