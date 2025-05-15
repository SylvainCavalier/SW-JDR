class AddCaracRefToSkills < ActiveRecord::Migration[7.1]
  def change
    add_reference :skills, :carac, null: true, foreign_key: true
  end
end
