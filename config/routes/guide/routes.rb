Rails.application.routes.draw do

  Guide::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :download do
    get :download, on: :collection
  end

  concern :import do
    get :import, on: :collection
    post :import, on: :collection
  end

  namespace "guide", path: ".s:site/guide" do
    namespace "apis" do
      get "questions" => "questions#index"
      get "procedures" => "procedures#index"
    end
  end

  content "guide" do
    get "/" => redirect { |p, req| "#{req.path}/nodes" }, as: :main
    resources :nodes, concerns: :deletion
    resources :genres, concerns: :deletion
    resources :guides, concerns: :deletion
    resources :questions, concerns: :deletion
    resources :procedures, concerns: [:deletion, :download, :import]
  end

  node "guide" do
    get "node(index.:format)" => "public#index", cell: "nodes/node"
    get "genre(index.:format)" => "public#index", cell: "nodes/genre"
    get "guide(index.:format)" => "public#index", cell: "nodes/guide"
    match "guide/guide(.:format)" => "public#guide", via: [:get, :post], cell: "nodes/guide"
    match "guide/result(.:format)" => "public#result", via: [:get, :post], cell: "nodes/guide"
    match "guide/answer(.:format)" => "public#answer", via: [:get, :post], cell: "nodes/guide"
  end

  part "guide" do
    get "node(index.:format)" => "public#index", cell: "parts/node"
  end
end
