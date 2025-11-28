class UpdateChatouilleDefaults < ActiveRecord::Migration[7.1]
  def change
    # Mettre à jour les crédits de départ pour correspondre à l'échelle Star Wars
    change_column_default :chatouille_states, :religion_credits, from: 100, to: 5000
  end
end

