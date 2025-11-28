class CreateGeneticStatistics < ActiveRecord::Migration[7.1]
  def change
    create_table :genetic_statistics do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :embryos_created, default: 0
      t.integer :embryos_recycled, default: 0
      t.integer :traits_applications_success, default: 0
      t.integer :traits_applications_partial, default: 0
      t.integer :traits_applications_failed, default: 0
      t.integer :gestations_completed, default: 0
      t.integer :clones_created, default: 0
      t.integer :clones_failed, default: 0

      t.timestamps
    end
  end
end

