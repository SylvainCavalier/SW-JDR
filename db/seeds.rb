puts "Reset the database..."
Skill.destroy_all
InventoryObject.destroy_all
User.destroy_all
Group.destroy_all
Race.destroy_all
ClassePerso.destroy_all

puts "Creating groups..."
group1 = Group.create!(name: "MJ", description: "Le groupe des Maîtres du Jeu. Prosternez vous.")
group2 = Group.create!(name: "PNJ", description: "Le groupe des marchands et auxiliaires de jeu")
group3 = Group.create!(name: "PJ", description: "Les joueurs jouent au jeu")
group4 = Group.create!(name: "Hackers", description: "Les hackers peuvent hacker les données des autres")

puts "Creating races..."
human = Race.create!(name: "Humain", description: "Une espèce polyvalente.")
kaminoan = Race.create!(name: "Kaminien", description: "Les bio-savants de Kamino.")
codruji = Race.create!(name: "Codru'Ji", description: "Les êtres à quatre bras de Munto Codru.")
toydarian = Race.create!(name: "Torydarien", description: "Les ingénieurs venus de Toydaria.")
clawdite = Race.create!(name: "Clawdite", description: "Les métamorphes de Zolan.")

puts "Creating classes..."
senator = ClassePerso.create!(name: "Sénateur", description: "Politicien influent.")
bio_savant = ClassePerso.create!(name: "Bio-savant", description: "Expert en sciences de la vie.")
autodidact = ClassePerso.create!(name: "Autodidacte", description: "Un apprenant autonome.")
mercenary = ClassePerso.create!(name: "Mercenaire", description: "Un combattant à louer.")
cyber_engineer = ClassePerso.create!(name: "Cyber-ingénieur", description: "Spécialiste des technologies avancées.")
smuggler = ClassePerso.create!(name: "Contrebandier", description: "Expert dans l'art de la contrebande.")

puts "Creating the users and assigning them to the corresponding groups, races, and classes..."
User.create!(username: "MJ", email: "mj@rpg.com", password: "motdepasse", hp_max: 1000, hp_current: 1000, credits: 100000, group: group1)

players = [
  { username: "Jarluc de Macharlon", email: "jarluc@rpg.com", race: human, classe_perso: senator, hp_max: 30, hp_current: 30, shield_max: 30, shield_current: 30, credits: 1000 },
  { username: "Kay Noah", email: "kay@rpg.com", race: kaminoan, classe_perso: bio_savant, hp_max: 30, hp_current: 30, shield_max: 30, shield_current: 30, credits: 1000 },
  { username: "Nuok", email: "nuok@rpg.com", race: codruji, classe_perso: autodidact, hp_max: 30, hp_current: 30, shield_max: 30, shield_current: 30, credits: 1000 },
  { username: "Pluto", email: "pluto@rpg.com", race: human, classe_perso: mercenary, hp_max: 30, hp_current: 30, shield_max: 30, shield_current: 30, credits: 1000 },
  { username: "Viggo", email: "viggo@rpg.com", race: toydarian, classe_perso: cyber_engineer, hp_max: 30, hp_current: 30, shield_max: 30, credits: 1000 },
  { username: "Mas Tandor", email: "mas@rpg.com", race: clawdite, classe_perso: smuggler, hp_max: 30, hp_current: 30, shield_max: 30, credits: 1000 }
]

puts "Creating healing inventory objects..."
inventory_objects = [
  { name: "Medipack", category: "soins", price: 50, description: "Redonne en PV le jet de médecine du soigneur divisé par deux.", rarity: "Commun" },
  { name: "Medipack +", category: "soins", price: 200, description: "Redonne en PV le jet de médecine du soigneur divisé par deux +1D", rarity: "Unco" },
  { name: "Medipack Deluxe", category: "soins", price: 500, description: "Redonne en PV le plein jet de médecine du soigneur", rarity: "Rare" },
  { name: "Antidote", category: "soins", price: 200, description: "Soigne le statut « empoisonné », +1D PV", rarity: "Unco" },
  { name: "Cuve à bacta", category: "soins", price: 5000, description: "Cuve fixe permettant la régénération de tous les PV/PF en 2h.", rarity: "Unco" },
  { name: "Extrait de Nysillin", category: "soins", price: 150, description: "Plante soignante de Félucia : +2D PV immédiat en action de soutien", rarity: "Unco" },
  { name: "Baume de Kolto", category: "soins", price: 800, description: "Baume miraculeux disparu de Manaan. +4D PV immédiat action soutien", rarity: "Très rare" },
  { name: "Sérum de Thyffera", category: "soins", price: 300, description: "Guérit les maladies communes", rarity: "Commun" },
  { name: "Rétroviral kallidahin", category: "soins", price: 500, description: "Guérit les maladies virales communes", rarity: "Commun" },
  { name: "Lotion réparatrice", category: "soins", price: 500, description: "Efface les traces de brûlure ou cicatrices", rarity: "Unco" },
  { name: "Draineur de radiations", category: "soins", price: 1000, description: "Guérit la radioactivité", rarity: "Unco" },
  { name: "Trompe-la-mort", category: "soins", price: 2000, description: "Soigne +2D PV à qqun passé sous -10 PV il y a – de 2 tours", rarity: "Rare" }
]

inventory_objects.each do |item|
  InventoryObject.create!(item)
end

puts "Creating statuses..."

statuses = [
  { name: "En forme", description: "En pleine santé", color: "#00FF00" }, # Vert clair
  { name: "Empoisonné", description: "Empoisonné", color: "#7F00FF" }, # Violet
  { name: "Irradié", description: "Irradié par des radiations", color: "#FFD700" }, # Or
  { name: "Agonisant", description: "À l'agonie, proche de la mort", color: "#8B0000" }, # Rouge foncé
  { name: "Mort", description: "Le joueur est mort", color: "#A9A9A9" }, # Gris
  { name: "Inconscient", description: "Inconscient, dans le coma", color: "#808080" }, # Gris foncé
  { name: "Malade", description: "Affection commune", color: "#FF4500" }, # Orange foncé
  { name: "Sonné", description: "Désorienté", color: "#4682B4" }, # Bleu acier
  { name: "Aveugle", description: "Impossible de voir", color: "#000000" }, # Noir
  { name: "Sourd", description: "Impossible d'entendre", color: "#C0C0C0" } # Argent
]

statuses.each do |status|
  Status.create!(status)
end

players.each do |player|
  user = User.create!(player.merge(password: "password", group: group3))
  user.statuses << Status.find_by(name: "En forme")
end

puts "Creating skills..."
Skill.create!(name: "Médecine", description: "Soigne les blessures.")
Skill.create!(name: "Res Corp", description: "Pour résister aux dégâts")

puts "Task completed!"
