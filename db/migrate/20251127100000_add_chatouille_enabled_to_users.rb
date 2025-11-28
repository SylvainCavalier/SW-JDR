class AddChatouilleEnabledToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :chatouille_enabled, :boolean, default: false, null: false
  end
end

