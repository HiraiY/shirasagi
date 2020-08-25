Rails.application.routes.draw do
  Gws::Affair::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :workflow do
    post :request_update, on: :member
    post :approve_update, on: :member
    post :remand_update, on: :member
    post :pull_up_update, on: :member
    post :restart_update, on: :member
    post :seen_update, on: :member
    match :request_cancel, on: :member, via: [:get, :post]
  end

  concern :plans do
    get :events, on: :collection
    get :print, on: :collection
    get :popup, on: :member
    get :copy, on: :member
    match :soft_delete, on: :member, via: [:get, :post]
  end

  concern :export do
    get :download, on: :collection
    get :import, on: :collection
    post :import, on: :collection
  end

  gws "affair" do
    get '/' => redirect { |p, req| "#{req.path}/attendance/time_cards/#{Time.zone.now.strftime('%Y%m')}" }, as: :main

    resources :capitals, concerns: :deletion
    resources :duty_calendars, concerns: :deletion
    resources :duty_notices, concerns: :deletion
    resources :shift_calendars, only: [:index]
    resources :shift_calendars, concerns: :deletion, except: [:index], path: "shift_calendars/u-:user" do
      get '/shift_records/' => redirect { |p, req| "#{req.path}/#{Time.zone.now.strftime('%Y/%m')}" }, as: :shift_record_main
      resources :shift_records, path: 'shift_records/:year/:month', concerns: [:deletion, :export], year: /(\d{4}|ID)/, month: /(\d{2}|ID)/
    end

    resources :duty_hours, concerns: :deletion
    resources :holiday_calendars, concerns: :deletion do
      resources :holidays, concerns: :deletion, path: "holidays/:year" do
        get :download, on: :collection
        match :import, on: :collection, via: %i[get post]
      end
    end

    get '/working_time/' => redirect { |p, req| "#{req.path}/calendar/" }, as: :working_time_main
    namespace "working_time" do
      get '/calendar/' => redirect { |p, req| "#{req.path}/#{Time.zone.now.strftime('%Y%m')}" }, as: :calendar_main
      get '/calendar/:year_month' => 'calendar#index', as: :calendar
      get '/calendar/:year_month/:day/:user/shift_record' => 'calendar#shift_record'
      post '/calendar/:year_month/:day/:user/shift_record' => 'calendar#shift_record'
      namespace 'management' do
        get "aggregate" => redirect { |p, req| "#{req.path}/default" }, as: :aggregate_main
        get "aggregate/:duty_type" => "aggregate#index", as: :aggregate
        get "aggregate/:duty_type/download" => "aggregate#download", as: :download_aggregate
        post "aggregate/:duty_type/download" => "aggregate#download"
      end
    end

    namespace "overtime" do
      resources :files, path: 'files/:state', concerns: [:deletion, :workflow]
      get "/search_approvers" => "search_approvers#index", as: :search_approvers
      match "/wizard/:id/approver_setting" => "wizard#approver_setting", via: [:get, :post], as: :approver_setting
      get "/wizard/:id/reroute" => "wizard#reroute", as: :reroute
      post "/wizard/:id/reroute" => "wizard#do_reroute", as: :do_reroute
      match "/wizard/:id" => "wizard#index", via: [:get, :post], as: :wizard

      resources :results, only: [:edit, :update]

      namespace 'management' do
        get "aggregate" => redirect { |p, req| "#{req.path}/users" }

        namespace 'aggregate' do
          get "users" => redirect { |p, req| "#{req.path}/total" }, as: :users_main
          get "users/:threshold" => "users#index", as: :users
          get "users/:threshold/download" => "users#download", as: :download_users
          post "users/:threshold/download" => "users#download"

          get "capitals" => redirect { |p, req| "#{req.path}/#{Time.zone.now.strftime('%Y')}" }, as: :capitals_main
          get "capitals/:year" => "capitals#index", as: :capitals, year: /(\d{4}|ID)/
          get "capitals/groups/:year/:month/:group" => "capitals#groups", as: :capitals_groups, year: /(\d{4}|ID)/, month: /(\d{2}|ID)/
          get "capitals/users/:year/:month/:group" => "capitals#users", as: :capitals_users, year: /(\d{4}|ID)/, month: /(\d{2}|ID)/

          get "capitals/download/:year" => "capitals#download", as: :capitals_download, year: /(\d{4}|ID)/
          get "capitals/download/groups/:year/:month/:group" => "capitals#download_groups", as: :capitals_download_groups, year: /(\d{4}|ID)/, month: /(\d{2}|ID)/
          get "capitals/download/users/:year/:month/:group" => "capitals#download_users", as: :capitals_download_users, year: /(\d{4}|ID)/, month: /(\d{2}|ID)/
          post "capitals/download/:year" => "capitals#download", year: /(\d{4}|ID)/
          post "capitals/download/groups/:year/:month/:group" => "capitals#download_groups", year: /(\d{4}|ID)/, month: /(\d{2}|ID)/
          post "capitals/download/users/:year/:month/:group" => "capitals#download_users", year: /(\d{4}|ID)/, month: /(\d{2}|ID)/

          get "search" => redirect { |p, req| "#{req.path}/groups" }, as: :search_main
          get "search/groups" => "search#groups", as: :search_groups
          get "search/groups/results" => "search#groups_results"
          get "search/users" => "search#users", as: :search_users
          get "search/users/results" => "search#users_results"
          get "search/download/groups" => "search#download_groups", as: :search_download_groups
          get "search/download/users" => "search#download_users", as: :search_download_users
          post "search/download/groups" => "search#download_groups"
          post "search/download/users" => "search#download_users"
        end
      end

      namespace "apis" do
        get "week_in_files/:uid" => "files#week_in", as: :files_week_in
        get "week_out_files/:uid" => "files#week_out", as: :files_week_out
      end
    end

    namespace "leave" do
      resources :files, path: 'files/:state', concerns: [:deletion, :workflow]
      get "/search_approvers" => "search_approvers#index", as: :search_approvers
      match "/wizard/:id/approver_setting" => "wizard#approver_setting", via: [:get, :post], as: :approver_setting
      get "/wizard/:id/reroute" => "wizard#reroute", as: :reroute
      post "/wizard/:id/reroute" => "wizard#do_reroute", as: :do_reroute
      match "/wizard/:id" => "wizard#index", via: [:get, :post], as: :wizard

      namespace "apis" do
        get "files/:id" => "files#show", as: :file
      end
    end

    namespace "apis" do
      namespace "overtime" do
        resources :results, only: [:edit, :update]
      end
      get "duty_hours" => "duty_hours#index"
      get "duty_notices" => "duty_notices#index"
      get "holiday_calendars" => "holiday_calendars#index"
    end

    namespace "attendance" do
      get '/time_cards/' => "time_cards#main", as: :time_card_main
      #get '/time_cards/' => redirect { |p, req| "#{req.path}/#{Time.zone.now.strftime('%Y%m')}" }, as: :time_card_main
      resources :time_cards, path: 'time_cards/:year_month', only: %i[index] do
        match :download, on: :collection, via: %i[get post]
        get :print, on: :collection
        post :enter, on: :collection
        post :leave, on: :collection
        post :leave, path: 'leave:date', on: :collection
        post :break_enter, path: 'break_enter:index', on: :collection
        post :break_leave, path: 'break_leave:index', on: :collection
        match :memo, path: ':day/memo', on: :collection, via: %i[get post]
        match :working_time, path: ':day/working_time', on: :collection, via: %i[get post]
        match :time, path: ':day/:type', on: :collection, via: %i[get post]
      end

      namespace 'management' do
        get '/' => redirect { |p, req| "#{req.path}/time_cards/#{Time.zone.now.strftime('%Y%m')}" }, as: :main
        get '/time_cards/' => redirect { |p, req| "#{req.path}/#{Time.zone.now.strftime('%Y%m')}" }, as: :time_card_main
        resources :time_cards, path: 'time_cards/:year_month', except: %i[new create edit update], concerns: %i[deletion] do
          match :memo, path: ':day/memo', on: :member, via: %i[get post]
          match :working_time, path: ':day/working_time', on: :member, via: %i[get post]
          match :time, path: ':day/:type', on: :member, via: %i[get post]
          match :download, on: :collection, via: %i[get post]
          match :lock, on: :collection, via: %i[get post]
          match :unlock, on: :collection, via: %i[get post]
        end
      end

      namespace 'apis' do
        namespace 'management' do
          get 'users' => 'users#index'
        end
      end
    end
  end
end
