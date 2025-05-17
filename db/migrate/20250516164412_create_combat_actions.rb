class CreateCombatActions < ActiveRecord::Migration[7.1]
  def change
    create_table :combat_actions do |t|
      t.references :actor, polymorphic: true, null: false
      t.references :target, polymorphic: true, null: false
      t.string :action_type
      t.string :value

      t.timestamps
    end
  end
end
