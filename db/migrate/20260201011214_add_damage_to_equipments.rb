class AddDamageToEquipments < ActiveRecord::Migration[7.1]
  def change
    add_column :equipments, :mastery, :integer, default: 0
    add_column :equipments, :bonus, :integer, default: 0
  end
end
