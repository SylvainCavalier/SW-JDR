class ChangeHeadquarterIdOnDefenses < ActiveRecord::Migration[7.1]
  def change
    change_column_null :defenses, :headquarter_id, true
  end
end
