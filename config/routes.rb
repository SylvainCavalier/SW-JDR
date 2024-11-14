Rails.application.routes.draw do
  devise_for :users

  resources :users, only: [] do
    resources :inventory_objects, only: [:index, :create, :destroy]
    member do
      post :toggle_shield
      post :update_hp
      post :recharger_bouclier
      post :spend_xp
      get :health_management
      post :purchase_hp
      get :settings
      patch :update_settings
    end
  end

  resources :transactions, only: [:new, :create]

  resources :holonews, only: [:index, :new, :create]

  get 'mj', to: 'pages#mj', as: 'mj_dashboard'

  get 'mj/infliger_degats', to: 'mj#infliger_degats', as: 'infliger_degats'
  post 'mj/infliger_degats', to: 'mj#apply_damage'

  get 'mj/fixer_pv_max', to: 'mj#fixer_pv_max', as: 'fixer_pv_max'
  post 'mj/fixer_pv_max', to: 'mj#update_pv_max'

  get 'mj/donner_xp', to: 'mj#donner_xp', as: 'donner_xp'
  post 'mj/donner_xp', to: 'mj#attribution_xp', defaults: { format: :turbo_stream }

  get 'mj/test_turbo', to: 'mj#test_turbo', defaults: { format: :turbo_stream }

  root 'pages#home'
end
