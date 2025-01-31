class AddVitesseToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :vitesse, :integer
  end
end
