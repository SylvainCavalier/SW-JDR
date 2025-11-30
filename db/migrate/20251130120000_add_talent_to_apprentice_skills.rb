class AddTalentToApprenticeSkills < ActiveRecord::Migration[7.1]
  def change
    add_column :apprentice_skills, :talent, :string, default: nil
  end
end

