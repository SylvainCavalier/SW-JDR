Rails.application.routes.draw do
  devise_for :users

  resources :transactions, only: [:new, :create]

  resources :holonews, only: [:index, :new, :create]

  root 'pages#home'
end
