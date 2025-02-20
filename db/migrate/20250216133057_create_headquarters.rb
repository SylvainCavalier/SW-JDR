class CreateHeadquarters < ActiveRecord::Migration[7.1]
  def change
    create_table :headquarters do |t|
      t.string :name
      t.string :location
      t.integer :credits
      t.text :description

      t.timestamps
    end
  end
end
