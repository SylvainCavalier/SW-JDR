class CreateUserInventoryObjects < ActiveRecord::Migration[7.1]
  def change
    create_table :user_inventory_objects do |t|
      t.references :user, null: false, foreign_key: true
      t.references :inventory_object, null: false, foreign_key: true
      t.integer :quantity

      t.timestamps
    end
  end
end
