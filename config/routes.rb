Rails.application.routes.draw do
  devise_for :users

  get "/service-worker.js", to: proc { [200, { "Content-Type" => "application/javascript" }, [Rails.application.assets.find_asset("service-worker.js").source]] }

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
      get :medipack
      get :healobjects
      post :buy_inventory_object
      post :heal_player
      get :patch
      post :equip_patch
      post :use_patch
    end

    collection do
      get :dice
      post :group_luck_roll
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

  get 'mj/fixer_statut', to: 'mj#fixer_statut', as: 'fixer_statut'
  post 'mj/fixer_statut', to: 'mj#update_statut'

  get 'donner_objet', to: 'mj#donner_objet'
  post 'update_objet', to: 'mj#update_objet'

  root 'pages#home'
end
