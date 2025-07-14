class CreateUserGenes < ActiveRecord::Migration[7.1]
  def change
    create_table :user_genes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :gene, null: false, foreign_key: true
      t.integer :level, default: 1

      t.timestamps
    end

    add_index :user_genes, [:user_id, :gene_id], unique: true
  end
end