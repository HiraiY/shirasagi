Rails.application.routes.draw do
  Gws::Facility::Initializer

  concern :plans do
    get :events, on: :collection
    get :print, on: :collection
    get :popup, on: :member
    get :copy, on: :member
    match :soft_delete, on: :member, via: [:get, :post]
  end

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :export do
    get :download, on: :collection
  end

  concern :import do
    get :import, on: :collection
    post :import, on: :collection
  end

  gws "facility" do
    get '/' => redirect { |p, req| "#{req.path}/schedule" }, as: :main
    get 'schedule' => 'schedule#index'
    get 'schedule/print' => 'schedule#print'
    get 'schedule/:facility' => 'schedule#show', as: :schedule_show

    scope :schedule do
      resources :facility_plans, path: ':facility/facility_plans', concerns: [:plans, :export], as: :schedule_plans
    end
    scope :plans do
      resources :plans, path: ':state', concerns: [:plans, :export, :deletion], except: [:destroy]
    end
    resources :trashes, concerns: [:deletion], except: [:new, :create, :edit, :update] do
      match :undo_delete, on: :member, via: [:get, :post]
    end

    resources :columns, path: 'items/:form_id/columns', concerns: [:deletion] do
      get :input_form, on: :collection
    end
    resources :items, concerns: [:deletion, :export, :import]
    resources :categories, concerns: [:deletion]
    namespace :usage do
      get '/' => 'main#index', as: :main
      resources :yearly, only: [:index], path: 'yearly/:yyyy', yyyy: %r{\d{4}} do
        get :download, on: :collection
      end
      resources :monthly, only: [:index], path: 'monthly/:yyyymm', yyyymm: %r{\d{6}} do
        get :download, on: :collection
      end
    end
    namespace :state do
      get '/' => 'main#index', as: :main
      resources :daily, only: [:index], path: 'daily/:yyyymmdd', yyyymmdd: %r{\d{8}} do
        get :download, on: :collection
      end
    end
    namespace "apis" do
      resources :items, only: [:show]
      scope path: ':facility' do
        get "plans/on_loan" => "plans#on_loan"
        post "plans/on_loan/:id/return_item" => "plans#return_item", as: :plans_return_item
      end
    end
  end
end
