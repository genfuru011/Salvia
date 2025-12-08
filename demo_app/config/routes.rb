Salvia::Router.draw do
  root to: "home#index"

  # ルートを追加
  resources :todos
  
  # Dashboard
  get "/dashboard", to: "dashboard#index"
  get "/inbox", to: "inbox#index"
  get "/projects", to: "projects#index"
  get "/settings", to: "settings#index"
end
