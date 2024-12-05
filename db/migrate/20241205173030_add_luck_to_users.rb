class AddLuckToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :luck, :boolean, default: false
  end
end
