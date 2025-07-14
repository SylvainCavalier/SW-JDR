puts "🧬 Chargement des gènes..."

gene_data_path = Rails.root.join("db", "seeds", "genes_seed.json")
gene_data = JSON.parse(File.read(gene_data_path))

gene_data.each do |data|
  gene = Gene.find_or_initialize_by(property: data["property"])
  gene.update!(
    positive: data["positive"],
    category: data["category"],
    description: data["description"],
    skill_bonuses: data["skill_bonuses"] || {},
    stats_bonuses: data["stats_bonuses"] || {},
    special_traits: data["special_traits"] || {}
  )
  puts "✅ Gène enregistré : #{gene.property}"
end

puts "✅ Tous les gènes ont été importés avec succès."