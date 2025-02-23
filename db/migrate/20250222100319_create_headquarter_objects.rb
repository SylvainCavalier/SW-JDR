class CreateHeadquarterObjects < ActiveRecord::Migration[7.1]
  def change
    create_table :headquarter_objects do |t|
      t.string :name, null: false
      t.integer :quantity, default: 1
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
