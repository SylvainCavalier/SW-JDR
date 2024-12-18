class RemodelPets < ActiveRecord::Migration[7.0]
  def change
    # Ajout des nouvelles colonnes
    add_column :pets, :description, :text
    add_column :pets, :category, :string
    add_column :pets, :url_image, :string

    # Suppression des colonnes obsolètes
    remove_column :pets, :res_corp, :integer
    remove_column :pets, :res_corp_bonus, :integer
    remove_column :pets, :speed, :float
    remove_column :pets, :accuracy, :float
    remove_column :pets, :dodge, :float
  end
end