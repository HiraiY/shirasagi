Rails.application.routes.draw do

  Guide::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  namespace "guide", path: ".s:site/guide" do
    resources :columns, concerns: [:deletion]
    resources :procedures, concerns: [:deletion]

    namespace "apis" do
      get "columns" => "columns#index"
      get "procedures" => "procedures#index"
    end
  end

  content "guide" do
    get "/" => redirect { |p, req| "#{req.path}/nodes" }, as: :main
    resources :nodes, concerns: :deletion
  end

  node "guide" do
    get "node(index.:format)" => "public#index", cell: "nodes/node"
    match "node/guide(.:format)" => "public#guide", via: [:get, :post], cell: "nodes/node"
    match "node/result(.:format)" => "public#result", via: [:get, :post], cell: "nodes/node"
    match "node/answer(.:format)" => "public#answer", via: [:get, :post], cell: "nodes/node"
  end
end
