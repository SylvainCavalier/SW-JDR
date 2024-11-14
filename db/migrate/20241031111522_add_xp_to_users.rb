class AddXpToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :xp, :integer, default: 0
  end
end
