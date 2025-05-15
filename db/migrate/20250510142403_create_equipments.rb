class CreateEquipments < ActiveRecord::Migration[7.1]
  def change
    create_table :equipments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :slot
      t.string :name
      t.text :effect
      t.boolean :equipped, default: false

      t.timestamps
    end
  end
end
