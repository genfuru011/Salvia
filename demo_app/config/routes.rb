Salvia::Router.draw do
  root to: "home#index"

  # ルートを追加
  resources :todos
  
  # Dashboard
  get "/dashboard", to: "dashboard#index"
end
