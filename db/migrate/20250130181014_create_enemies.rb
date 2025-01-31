class CreateEnemies < ActiveRecord::Migration[7.1]
  def change
    create_table :enemies do |t|
      t.string :type
      t.integer :number
      t.integer :hp_current
      t.integer :hp_max
      t.integer :shield_current
      t.integer :shield_max
      t.string :status

      t.timestamps
    end
  end
end
