class AddSizeAndWeightToPets < ActiveRecord::Migration[7.1]
  def change
    # Ajout des colonnes avec des valeurs par défaut
    add_column :pets, :size, :integer, default: 100, null: false
    add_column :pets, :weight, :integer, default: 50, null: false

    # Mise à jour des enregistrements existants
    reversible do |dir|
      dir.up do
        # S'assurer que tous les pets existants ont des valeurs par défaut
        Pet.update_all(size: 100, weight: 50)
      end
    end
  end
end
