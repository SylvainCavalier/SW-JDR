class CreatePetInventoryObjects < ActiveRecord::Migration[7.1]
  def change
    create_table :pet_inventory_objects do |t|
      t.references :pet, null: false, foreign_key: true
      t.references :inventory_object, null: false, foreign_key: true

      t.timestamps
    end
  end
end
