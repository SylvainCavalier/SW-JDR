Rails.application.routes.draw do
  devise_for :users

  get "/service-worker.js", to: "pwa#service_worker", as: :pwa_service_worker, format: :js
  get "manifest" => "pwa#manifest", as: :pwa_manifest
  get "team" => "pages#team", as: :team

  resources :users, only: [:show] do
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
      post :equip_patch
      post :use_patch
      post :sell_item
      post :give_item
      post :equip_injection
      post :deactivate_injection
      post :equip_implant
      post :unequip_implant
      get :sphero
      get :edit_notes
      patch :update_notes
      patch :avatar_upload
      patch :update_skills
      post :add_equipment
      patch :equip_equipment
      delete "equipment/:slot", to: "users#remove_equipment", as: :remove_equipment
      delete "equipment/delete/:equipment_id", to: "users#delete_equipment"
      patch :update_info
    end

    collection do
      get :dice
      post :group_luck_roll
    end
  end

  patch "users/:id/remove_item/:item_id", to: "users#remove_item", as: :remove_item_user

  resources :transactions, only: [:new, :create]

  resources :subscriptions, only: [:create, :destroy]

  resource :headquarter, only: [:show, :edit, :update] do
    collection do
      get :inventory
      get :observation
      get :credits
      post :transfer_credits
      get :buildings
      get :personnel
      patch :inventory
      post :add_item
      delete "remove_personnel/:id", to: "headquarter#remove_personnel", as: :remove_personnel
      get :defenses
      post "buy_defense/:id", to: "headquarter#buy_defense", as: :buy_defense
    end
  end

  resources :buildings, only: [] do
    patch :upgrade, on: :member
    patch :assign_pet, on: :member
    patch :set_chief_pet, on: :member
    delete :remove_pet, on: :member
  end

  resources :holonews, only: [:index, :new, :create]
  get 'holonews/count', to: 'holonews#count'

  resources :enemies, only: [:create, :update, :destroy]

  resources :apprentices do
    post :create_from_pet, on: :collection, as: :create
  end

  resources :pets do
    collection do
      get 'graveyard', to: 'pets#graveyard'
    end
    member do
      post 'perform_action', to: 'pets#perform_action'
      post 'heal', to: 'pets#heal'
      post 'associate', to: 'pets#associate'
      post 'dissociate', to: 'pets#dissociate'
      post 'recharger_bouclier', to: 'pets#recharger_bouclier'
    end
  end

  get 'science', to: 'science#science', as: 'science'
  get "science/crafts", to: "science#crafts", as: :science_crafts
  get "science/bestiaire", to: "science#bestiaire", as: :science_bestiaire
  post 'attempt_craft', to: 'science#attempt_craft'
  post '/science/attempt_transfer', to: 'science#attempt_transfer', as: 'attempt_transfer_science'
  get "/science/players", to: "science#players", as: :science_players
  get "science/showbestiaire/:id", to: "science#showbestiaire", as: :showbestiaire
  get "science/genetique", to: "science#genetique", as: :genetique_dashboard
  get "science/labo",      to: "science#labo",      as: :labo_genetique
  get "science/cultiver",  to: "science#cultiver",  as: :cultiver_embryon
  get "science/traits",    to: "science#traits",    as: :appliquer_traits
  get "science/clonage",   to: "science#clonage",   as: :clonage
  get "science/stats",     to: "science#stats",     as: :genetique_stats
  get "science/labo", to: "science#labo", as: :science_labo
  post "science/recherche_gene", to: "science#recherche_gene", as: :recherche_gene

  resources :science, only: [] do
    collection do
      get :list
      post :buy_inventory_object
      get :settings, to: "science#settings"
      post :update_settings, to: "science#update_settings"
    end
  end

  resources :goods_crates, only: [:index, :create, :destroy]

  get 'wine_cellar', to: 'wine_cellar#index', as: 'wine_cellar'
  post 'wine_cellar/add_bottle', to: 'wine_cellar#add_bottle', as: 'add_bottle_wine_cellar'
  post 'wine_cellar/remove_bottle', to: 'wine_cellar#remove_bottle', as: 'remove_bottle_wine_cellar'

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

  get 'mj/fixer-points', to: 'mj#fixer_points', as: 'fixer_points'
  patch 'mj/update_points/:id', to: 'mj#update_points', as: 'update_points'
  patch 'mj/reset_points/:id', to: 'mj#reset_points', as: 'reset_points'
  post "mj/attribution_study_points", to: "mj#attribution_study_points", as: :attribution_study_points

  get 'mj/unlock_drink', to: 'mj#unlock_drink', as: 'mj_unlock_drink'
  post 'mj/unlock_drink', to: 'mj#update_unlock_drink', as: 'mj_update_unlock_drink'

  get 'mj/infliger_degats', to: 'mj#infliger_degats', as: 'infliger_degats'
  post 'mj/infliger_degats', to: 'mj#apply_damage'
  post 'apply_damage_pets', to: 'mj#apply_damage_pets'
  post 'apply_damage_spheros', to: 'mj#apply_damage_spheros'

  # Balles perdues (MJ uniquement)
  post 'mj/balles_perdues', to: 'mj#balles_perdues', as: 'mj_balles_perdues'

  get 'mj/fixer_pv_max', to: 'mj#fixer_pv_max', as: 'fixer_pv_max'
  post 'mj/fixer_pv_max', to: 'mj#update_pv_max'
  post 'mj/apply_hp_bonus', to: 'mj#apply_hp_bonus'
  patch "/mj/users/:id/update_caracs", to: "mj#update_user_caracs", as: :mj_update_user_caracs

  get 'mj/donner_xp', to: 'mj#donner_xp', as: 'donner_xp'
  post 'mj/donner_xp', to: 'mj#attribution_xp', defaults: { format: :turbo_stream }

  get 'mj/test_turbo', to: 'mj#test_turbo', defaults: { format: :turbo_stream }

  get 'mj/fixer_statut', to: 'mj#fixer_statut', as: 'fixer_statut'
  post 'mj/fixer_statut', to: 'mj#update_statut'
  post "mj/fixer_statut_pets", to: "mj#fixer_statut_pets"

  get 'donner_objet', to: 'mj#donner_objet'
  post 'update_objet', to: 'mj#update_objet'

  get 'fix_pets', to: 'mj#fix_pets'
  patch 'fix_pets/:id', to: 'mj#fix_pets', as: 'fix_pet'
  post "mj/send_pet_action_points", to: "mj#send_pet_action_points", as: "send_pet_action_points"

  get "mj/sphero", to: "mj#sphero", as: "mj_sphero"
  post "mj/sphero/create", to: "mj#create_sphero", as: "mj_create_sphero"

  get 'mj/vaisseaux', to: 'mj#vaisseaux', as: 'mj_vaisseaux'
  patch 'mj/vaisseaux/:id/update_ship', to: 'mj#update_ship', as: 'mj_update_ship'
  patch 'mj/vaisseaux/:id/update_ship_stats', to: 'mj#update_ship_stats', as: 'mj_update_ship_stats'
  patch 'mj/vaisseaux/:id/update_ship_skills', to: 'mj#update_ship_skills', as: 'mj_update_ship_skills'
  patch 'mj/vaisseaux/:id/update_ship_weapons', to: 'mj#update_ship_weapons', as: 'mj_update_ship_weapons'
  patch 'mj/vaisseaux/:id/update_ship_status', to: 'mj#update_ship_status', as: 'mj_update_ship_status'
  post 'mj/vaisseaux/:id/add_ship_weapon', to: 'mj#add_ship_weapon', as: 'mj_add_ship_weapon'
  delete 'mj/vaisseaux/:ship_id/weapons/:weapon_id', to: 'mj#delete_ship_weapon', as: 'mj_delete_ship_weapon'

  get 'combat', to: 'combat#index', as: 'combat'
  get 'mj/combat', to: 'combat#index', as: 'mj_combat'
  
  post "combat/add_enemy", to: "combat#add_enemy", as: :add_enemy
  delete "combat/remove_enemy/:id", to: "combat#remove_enemy", as: :remove_enemy
  patch "combat/update_stat", to: "combat#update_stat", as: :update_stat
  patch "combat/update_status", to: "combat#update_status", as: :update_combat_status
  patch "combat/remove_participant/:type/:id", to: "combat#remove_participant", as: :remove_participant
  patch "combat/increment_turn", to: "combat#increment_turn", as: :increment_turn
  patch "combat/decrement_turn", to: "combat#decrement_turn", as: :decrement_turn
  post "combat/add_pj", to: "combat#add_pj_to_combat", as: :add_pj_to_combat
  post "combat/add_pet", to: "combat#add_pet_to_combat", as: :add_pet_to_combat

  post 'reset_health', to: 'mj#reset_health', as: :reset_health

  get 'rules', to: 'pages#rules', as: 'rules'

  get 'ship_objects/new'
  get 'ship_objects/create'
  get 'ship_objects/edit'
  get 'ship_objects/update'
  get 'ship_objects/destroy'
  get 'ships/index'
  get 'ships/show'
  get 'ships/new'
  get 'ships/create'
  get 'ships/edit'
  get 'ships/update'
  get 'ships/destroy'
  get 'ships/set_active'
  get 'ships/dock'
  get 'ships/undock'
  get 'ships/inventory'
  get 'ships/improve'
  get 'ships/repair'

  resources :ships do
    member do
      patch :set_active
      get :inventory
      get :improve
      patch :upgrade
      patch :upgrade_sensor
      patch :upgrade_hp_max
      patch :buy_weapon
      patch :install_weapon
      patch :uninstall_weapon
      patch :sell_weapon
      patch :buy_launcher
      patch :buy_ammunition
      patch :buy_turret
      patch :install_turret
      patch :uninstall_turret
      patch :sell_turret
      patch :upgrade_weapon_damage
      patch :upgrade_weapon_aim
      patch :buy_special_equipment
      patch :install_special_equipment
      patch :uninstall_special_equipment
      patch :sell_special_equipment
      patch :dock
      patch :undock
      get :crew
      patch :assign_crew
      delete :remove_crew_member
      get :repair
      patch :use_repair_kit
      patch :deploy_astromech_droid
    end
    resources :ship_objects, only: [:new, :create, :edit, :update, :destroy]
  end

  # Pazaak mini-jeu
  namespace :pazaak do
    resource :menu, only: :show, controller: :menus
    resource :deck, only: [:show, :update], controller: :decks
    resource :stats, only: :show, controller: :stats
    resources :lobbies, only: :index do
      collection do
        post :ping
      end
    end
    resources :invitations, only: [:create, :update]
    resources :games, only: [:show, :create] do
      member do
        post :abandon
      end
      resources :moves, only: :create
    end
  end
  get "/pazaak", to: "pazaak/menus#show"

  root 'pages#home'
end
