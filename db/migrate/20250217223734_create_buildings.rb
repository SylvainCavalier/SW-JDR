class CreateBuildings < ActiveRecord::Migration[7.0]
  def change
    create_table :buildings do |t|
      t.string :name
      t.integer :level, default: 0
      t.string :description
      t.integer :price
      t.string :category
      t.references :chief_pet, foreign_key: { to_table: :pets }, index: true, null: true
      t.references :headquarter, null: false, foreign_key: { to_table: :headquarters }
      t.jsonb :properties, default: {} 

      t.timestamps
    end
  end
end
