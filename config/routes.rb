Rails.application.routes.draw do
  devise_for :users

  get "service-worker" => "pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "pwa#manifest", as: :pwa_manifest

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
      get :inventory
      post :sell_item
      post :give_item
      get :injections
      post :equip_injection
      post :deactivate_injection
      get :implants
      post :equip_implant
      post :unequip_implant
      get :sphero
    end

    collection do
      get :dice
      post :group_luck_roll
    end
  end

  resources :transactions, only: [:new, :create]

  resources :holonews, only: [:index, :new, :create]

  resources :enemies, only: [:create, :update, :destroy]

  resources :pets do
    collection do
      get 'graveyard', to: 'pets#graveyard'
    end
    member do
      post 'perform_action', to: 'pets#perform_action'
      post 'heal', to: 'pets#heal'
      post 'associate', to: 'pets#associate'
      post 'dissociate', to: 'pets#dissociate'
    end
  end

  get 'science', to: 'science#science', as: 'science'
  get "science/crafts", to: "science#crafts", as: :science_crafts
  post 'attempt_craft', to: 'science#attempt_craft'
  post '/science/attempt_transfer', to: 'science#attempt_transfer', as: 'attempt_transfer_science'
  get "/science/players", to: "science#players", as: :science_players

  resources :science, only: [] do
    collection do
      get :list
      post :buy_inventory_object
      get :settings, to: "science#settings"
      post :update_settings, to: "science#update_settings"
    end
  end

  resources :spheros, only: [:destroy] do
    member do
      post :activate
      post :deactivate
      post :transfer
      post :repair
      post :repair_kit
      post :recharge
      post :protect
      post :attack
      post :use_medipack 
      post :add_medipack
    end
  end

  get 'manage_pet', to: 'pets#manage_pet', as: :manage_pet

  get 'mj', to: 'pages#mj', as: 'mj_dashboard'

  get 'mj/infliger_degats', to: 'mj#infliger_degats', as: 'infliger_degats'
  post 'mj/infliger_degats', to: 'mj#apply_damage'
  post 'apply_damage_pets', to: 'mj#apply_damage_pets'
  post 'apply_damage_spheros', to: 'mj#apply_damage_spheros'

  get 'mj/fixer_pv_max', to: 'mj#fixer_pv_max', as: 'fixer_pv_max'
  post 'mj/fixer_pv_max', to: 'mj#update_pv_max'
  post 'mj/apply_hp_bonus', to: 'mj#apply_hp_bonus'

  get 'mj/donner_xp', to: 'mj#donner_xp', as: 'donner_xp'
  post 'mj/donner_xp', to: 'mj#attribution_xp', defaults: { format: :turbo_stream }

  get 'mj/test_turbo', to: 'mj#test_turbo', defaults: { format: :turbo_stream }

  get 'mj/fixer_statut', to: 'mj#fixer_statut', as: 'fixer_statut'
  post 'mj/fixer_statut', to: 'mj#update_statut'

  get 'donner_objet', to: 'mj#donner_objet'
  post 'update_objet', to: 'mj#update_objet'

  get 'fix_pets', to: 'mj#fix_pets'
  patch 'fix_pets/:id', to: 'mj#fix_pets', as: 'fix_pet'
  post "mj/send_pet_action_points", to: "mj#send_pet_action_points", as: "send_pet_action_points"

  get "mj/sphero", to: "mj#sphero", as: "mj_sphero"
  post "mj/sphero/create", to: "mj#create_sphero", as: "mj_create_sphero"

  get "mj/combat", to: "combat#index", as: :mj_combat
  post "mj/combat/start", to: "combat#start_combat", as: :start_combat
  post "mj/combat/end", to: "combat#end_combat", as: :end_combat
  post "mj/combat/add_enemy", to: "combat#add_enemy", as: :add_enemy
  delete "mj/combat/remove_enemy/:id", to: "combat#remove_enemy", as: :remove_enemy
  patch "mj/combat/update_enemy_stat/:id", to: "combat#update_stat", as: :update_enemy_stat

  get 'combat', to: 'pages#combat', as: 'combat'
  post "combat/add_pj", to: "combat#add_pj_to_combat", as: :add_pj_to_combat

  post 'reset_health', to: 'mj#reset_health', as: :reset_health

  get 'rules', to: 'pages#rules', as: 'rules'

  root 'pages#home'
end
