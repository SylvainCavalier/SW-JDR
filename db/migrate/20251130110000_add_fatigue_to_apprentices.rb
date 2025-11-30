class AddFatigueToApprentices < ActiveRecord::Migration[7.1]
  def change
    add_column :apprentices, :fatigue, :integer, default: 100, null: false
  end
end

