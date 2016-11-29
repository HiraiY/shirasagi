SS::Application.routes.draw do

  Webmail::Initializer

  concern :deletion do
    get :delete, :on => :member
    delete action: :destroy_all, :on => :collection
  end

  concern :mail do
    collection do
      put :set_seen
      put :unset_seen
      put :set_star
      put :unset_star
    end
    member do
      get :download
      get :attachment
      get :header_view
      get :source_view
      put :set_seen
      put :unset_seen
      put :set_star
      put :unset_star
    end
  end

  namespace "webmail", path: ".webmail" do
    get "/" => redirect { |p, req| "#{req.path}/user_profile" }, as: :cur_user

    resources :mails, concerns: [:deletion, :mail], path: 'mails/:box', box: /[^\/]+/, defaults: { box: 'INBOX' }
    resources :mailboxes, concerns: [:deletion]
    resource :account_setting, only: [:show, :edit, :update]
    resource :cache_setting, only: [:show, :update]
  end
end
