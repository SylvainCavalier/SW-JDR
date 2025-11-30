class CreateLightSabers < ActiveRecord::Migration[7.1]
  def change
    create_table :light_sabers do |t|
      t.references :apprentice, null: true, foreign_key: true
      t.string :name, default: "Sabre laser"
      t.string :color, default: "bleu"
      t.string :crystal, default: "Cristal Kyber"
      t.integer :damage, default: 5
      t.integer :damage_bonus, default: 0
      t.string :special_attribute
      t.text :description

      t.timestamps
    end
  end
end

