class AddRobustesseToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :robustesse, :boolean, default: false
  end
end
