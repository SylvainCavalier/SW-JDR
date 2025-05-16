class AddCharacterDetailsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :sex, :string, null: true
    add_column :users, :age, :integer, null: true
    add_column :users, :height, :integer, null: true
    add_column :users, :weight, :integer, null: true
    add_column :users, :dark_side_points, :integer, default: 0, null: true
    add_column :users, :cyber_points, :integer, default: 0, null: true
  end
end
