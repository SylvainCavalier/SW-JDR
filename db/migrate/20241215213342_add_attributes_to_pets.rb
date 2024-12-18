class AddAttributesToPets < ActiveRecord::Migration[7.1]
  def change
    # Ajouter les colonnes avec leurs valeurs par défaut
    add_column :pets, :mood, :integer, default: 0, null: false
    add_column :pets, :loyalty, :integer, default: 0, null: false
    add_column :pets, :hunger, :integer, default: 0, null: false
    add_column :pets, :fatigue, :integer, default: 0, null: false

    # Ajouter la référence status sans contrainte NOT NULL pour l'instant
    add_reference :pets, :status, foreign_key: true, null: true

    # Mettre à jour les données existantes avec le statut par défaut
    reversible do |dir|
      dir.up do
        default_status = Status.find_by(name: "En forme") || Status.create!(name: "En forme", description: "En pleine santé", color: "#1EDD88")
        Pet.where(status_id: nil).update_all(status_id: default_status.id)
      end
    end

    # Appliquer la contrainte NOT NULL après la mise à jour des données
    change_column_null :pets, :status_id, false
  end
end
