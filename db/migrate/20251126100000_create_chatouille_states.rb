class CreateChatouilleStates < ActiveRecord::Migration[7.1]
  def change
    create_table :chatouille_states do |t|
      t.references :user, null: false, foreign_key: true
      
      # Ressources principales
      t.integer :faith_points, default: 10, null: false  # Points de foi
      t.integer :missionaries, default: 1, null: false   # Missionnaires
      t.integer :religion_credits, default: 100, null: false  # Crédits dédiés à la religion
      
      # Parts de marché (en pourcentage, 1-100)
      t.decimal :market_share, precision: 5, scale: 2, default: 1.0, null: false
      
      # Influence politique (0-100)
      t.integer :political_influence, default: 0, null: false
      
      # Étape actuelle du jeu (1-4)
      t.integer :current_step, default: 1, null: false
      
      # Temples et infrastructures
      t.integer :temples_count, default: 0, null: false
      t.integer :flying_temple, default: 0, null: false  # Temple volant (0 ou 1)
      
      # Progression politique
      t.boolean :council_observer, default: false, null: false
      t.boolean :council_member, default: false, null: false
      
      # Événements
      t.integer :current_event_index, default: nil  # Index de l'événement en cours
      t.boolean :event_available, default: false, null: false
      t.jsonb :completed_events, default: []  # Liste des événements complétés
      
      # Expansion galactique
      t.jsonb :planets_reached, default: []  # Planètes atteintes par les missionnaires
      
      # Statistiques
      t.integer :total_converts, default: 0, null: false
      t.integer :scandals_survived, default: 0, null: false
      t.integer :miracles_performed, default: 0, null: false
      
      t.timestamps
    end
  end
end

