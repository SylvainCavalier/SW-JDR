class AddSpecialTraitsToPets < ActiveRecord::Migration[7.1]
  def change
    add_column :pets, :special_traits, :jsonb, default: []
    add_column :pets, :origin_embryo_id, :bigint
    add_index :pets, :origin_embryo_id
  end
end

