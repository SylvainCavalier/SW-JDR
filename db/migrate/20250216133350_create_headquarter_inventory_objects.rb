class CreateHeadquarterInventoryObjects < ActiveRecord::Migration[7.1]
  def change
    create_table :headquarter_inventory_objects do |t|
      t.references :headquarter, null: false, foreign_key: { to_table: :headquarters }
      t.references :inventory_object, null: false, foreign_key: true
      t.integer :quantity

      t.timestamps
    end
  end
end
