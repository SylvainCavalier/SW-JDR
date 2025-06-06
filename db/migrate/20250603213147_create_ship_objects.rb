class CreateShipObjects < ActiveRecord::Migration[7.1]
  def change
    create_table :ship_objects do |t|
      t.references :ship, null: false, foreign_key: true
      t.string :name
      t.integer :quantity
      t.string :description

      t.timestamps
    end
  end
end
