class AddHpBonusToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :hp_bonus, :integer
  end
end
