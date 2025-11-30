class AddMidiChloriansRevealedToApprentices < ActiveRecord::Migration[7.1]
  def change
    add_column :apprentices, :midi_chlorians_revealed, :boolean, default: false, null: false
  end
end

