class CreateHolonewReads < ActiveRecord::Migration[7.1]
  def change
    create_table :holonew_reads do |t|
      t.references :user, null: false, foreign_key: true
      t.references :holonew, null: false, foreign_key: true
      t.boolean :read

      t.timestamps
    end
  end
end
