Rails.application.routes.draw do
  Gws::Monitor::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :soft_deletion do
    match :soft_delete, on: :member, via: [:get, :post]
    post :soft_delete_all, on: :collection
  end

  concern :state_change do
    post :public, on: :member
    post :preparation, on: :member
    post :public_all, on: :collection
    post :preparation_all, on: :collection
  end

  concern :topic_comment do
    resources :comments, path: "comments", controller: 'comments', concerns: [:deletion] do
      match :not_applicable, on: :collection, via: %i[get post]
      match :publish, on: :member, via: %i[get post]
      match :depublish, on: :member, via: %i[get post]
      match :reply, on: :member, via: %i[get post]
    end
  end

  concern :topic_files do
    get :all_topic_files, on: :member
  end

  gws 'monitor' do
    get '/' => redirect { |p, req| "#{req.path}/-/topics" }, as: :main

    scope(path: ':category', defaults: { category: '-' }) do
      resources :topics, path: "topics/(:approve_state_filter)", concerns: [:state_change, :topic_comment, :topic_files],
                except: [:new, :create, :edit, :update, :destroy], constraints: { approve_state_filter: /approve|request/ } do
        match :forward, on: :member, via: [:get, :post]
      end

      namespace "management" do
        get '/' => redirect { |p, req| "#{req.path}/topics" }, as: :main

        resources :topics, concerns: [:soft_deletion, :state_change, :topic_comment], except: [:destroy] do
          match :publish, on: :member, via: %i[get post]
          get :download, on: :member
          post :close, on: :member
          post :open, on: :member
          get :file_download, on: :member
        end
        resources :trashes, concerns: [:deletion], except: [:new, :create, :edit, :update] do
          match :undo_delete, on: :member, via: %i[get post]
        end
      end
    end

    resources :categories, concerns: [:deletion]

    namespace "workflow" do
      scope "wizard/:id", as: "wizard" do
        match "" => "wizard#index", via: [:get, :post]
        match "approver_setting" => "wizard#approver_setting", via: [:get, :post], as: "approver_setting"
        get "reroute" => "wizard#reroute", as: "reroute"
        post "reroute" => "wizard#do_reroute"
        get "approveByDelegatee" => "wizard#approve_by_delegatee", as: "approve_by_delegatee"
      end

      resources :pages, concerns: [:deletion] do
        post :request_update, on: :member
        post :approve_update, on: :member
        post :remand_update, on: :member
        post :pull_up_update, on: :member
        post :restart_update, on: :member
        post :seen_update, on: :member
        match :request_cancel, on: :member, via: [:get, :post]
      end
    end

    namespace "apis" do
      get "categories" => "categories#index"
    end
  end
end
