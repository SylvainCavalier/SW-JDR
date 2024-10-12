Rails.application.routes.draw do
  devise_for :users

  resources :users, only: [] do
    member do
      post :toggle_shield
    end
  end

  resources :transactions, only: [:new, :create]

  resources :holonews, only: [:index, :new, :create]

  get 'mj', to: 'pages#mj', as: 'mj_dashboard'

  get 'mj/infliger_degats', to: 'mj#infliger_degats', as: 'infliger_degats'
  post 'mj/infliger_degats', to: 'mj#apply_damage'

  get 'mj/fixer_pv_max', to: 'mj#fixer_pv_max', as: 'fixer_pv_max'
  post 'mj/fixer_pv_max', to: 'mj#update_pv_max'

  root 'pages#home'
end
