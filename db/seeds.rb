puts "Adding new skills..."

new_skills = [
  { name: "Vitesse", description: "Augmente les déplacements rapides." },
  { name: "Précision", description: "Améliore les tirs à distance." },
  { name: "Esquive", description: "Réduit les chances d'être touché." }
]

new_skills.each do |skill|
  Skill.find_or_create_by!(name: skill[:name]) do |s|
    s.description = skill[:description]
  end
end

puts "✅ New skills added successfully!"
