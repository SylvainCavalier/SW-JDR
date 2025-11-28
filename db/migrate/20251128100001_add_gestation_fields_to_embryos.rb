class AddGestationFieldsToEmbryos < ActiveRecord::Migration[7.1]
  def change
    add_column :embryos, :modified, :boolean, default: false
    add_column :embryos, :gestation_started_at, :datetime
    add_column :embryos, :gestation_days_total, :integer
    add_column :embryos, :gestation_days_remaining, :integer
    add_column :embryos, :applied_genes, :jsonb, default: []
    add_column :embryos, :final_stats, :jsonb, default: {}
    add_column :embryos, :gestation_tube, :integer # 1, 2 ou 3
  end
end

