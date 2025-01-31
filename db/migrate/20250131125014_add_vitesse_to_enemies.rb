class AddVitesseToEnemies < ActiveRecord::Migration[7.1]
  def change
    add_column :enemies, :vitesse, :integer
  end
end
