class AddCreatureAndAgeToPets < ActiveRecord::Migration[7.1]
  def change
    add_column :pets, :creature, :boolean, default: false, null: false
    add_column :pets, :age, :integer, default: 1, null: false
  end
end
