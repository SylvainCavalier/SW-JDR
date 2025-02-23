class RenameNameToJediNameAndAddJediAttributesToApprentices < ActiveRecord::Migration[7.1]
  def change
    rename_column :apprentices, :name, :jedi_name
    add_column :apprentices, :side, :integer, default: 0
    add_column :apprentices, :speciality, :string, default: "Commun"
    add_column :apprentices, :midi_chlorians, :integer
    add_column :apprentices, :saber_style, :string
  end
end
