class CreatePets < ActiveRecord::Migration[7.1]
  def change
    create_table :pets do |t|
      t.string :name
      t.string :race
      t.integer :hp_current
      t.integer :hp_max
      t.integer :res_corp
      t.integer :res_corp_bonus
      t.float :speed
      t.integer :damage_1
      t.integer :damage_2
      t.float :accuracy
      t.float :dodge
      t.string :weapon_1
      t.string :weapon_2

      t.timestamps
    end
  end
end
