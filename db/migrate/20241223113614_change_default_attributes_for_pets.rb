class ChangeDefaultAttributesForPets < ActiveRecord::Migration[7.1]
  def change
    change_column_default :pets, :mood, 2
    change_column_default :pets, :loyalty, 2
    change_column_default :pets, :hunger, 2
    change_column_default :pets, :fatigue, 2
  end
end
