class CreateGoodsCrates < ActiveRecord::Migration[7.1]
  def change
    create_table :goods_crates do |t|
      t.string :content
      t.integer :quantity
      t.string :origin_planet
      t.integer :price_per_crate
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
