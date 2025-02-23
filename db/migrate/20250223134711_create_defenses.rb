class CreateDefenses < ActiveRecord::Migration[7.1]
  def change
    create_table :defenses do |t|
      t.string :name, null: false
      t.integer :price, null: false
      t.text :description, null: false
      t.integer :bonus, default: 0
      t.references :headquarter, null: false, foreign_key: { to_table: :headquarters }

      t.timestamps
    end
  end
end
