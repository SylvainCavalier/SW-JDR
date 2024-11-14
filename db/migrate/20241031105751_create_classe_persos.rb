class CreateClassePersos < ActiveRecord::Migration[7.1]
  def change
    create_table :classe_persos do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
