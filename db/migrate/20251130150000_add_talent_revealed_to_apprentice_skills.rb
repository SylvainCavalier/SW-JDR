class AddTalentRevealedToApprenticeSkills < ActiveRecord::Migration[7.1]
  def change
    add_column :apprentice_skills, :talent_revealed, :boolean, default: false, null: false
    
    # Marquer les talents existants comme révélés (pour la compatibilité)
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE apprentice_skills SET talent_revealed = true WHERE talent IS NOT NULL
        SQL
      end
    end
  end
end

