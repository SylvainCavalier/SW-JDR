puts "Reset the database..."

# Supprimer les dépendances
UserSkill.destroy_all
UserInventoryObject.destroy_all
UserStatus.destroy_all
Transaction.destroy_all

# Supprimer les enregistrements principaux
User.destroy_all
Skill.destroy_all
InventoryObject.destroy_all
Status.destroy_all
ClassePerso.destroy_all
Race.destroy_all
Group.destroy_all

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
  { name: "Extrait de Nysillin", category: "soins", price: 150, description: "Plante soignante de Félucia : +2D PV immédiat en action de soutien", rarity: "Unco" },
  { name: "Baume de Kolto", category: "soins", price: 800, description: "Baume miraculeux disparu de Manaan. +4D PV immédiat action soutien", rarity: "Très rare" },
  { name: "Sérum de Thyffera", category: "soins", price: 300, description: "Guérit les maladies communes", rarity: "Commun" },
  { name: "Rétroviral kallidahin", category: "soins", price: 500, description: "Guérit les maladies virales communes", rarity: "Commun" },
  { name: "Draineur de radiations", category: "soins", price: 1000, description: "Guérit la radioactivité", rarity: "Unco" },
  { name: "Trompe-la-mort", category: "soins", price: 2000, description: "Soigne +2D PV à qqun passé sous -10 PV il y a – de 2 tours", rarity: "Rare" },
  { name: "Homéopathie", category: "soins", price: 0, description: "Soigne intégralement un personnage qui est à 5 PV ou moins de son maximum", rarity: "Don" }
]

inventory_objects.each do |item|
  InventoryObject.create!(item)
end

patches = [
  { name: "Poisipatch", description: "Quand le porteur est empoisonné, le patch libère un antidote", price: 50, category: "patch" },
  { name: "Traumapatch", description: "Quand le porteur est blessé, le patch libère 1D PV de bacta", price: 50, category: "patch" },
  { name: "Stimpatch", description: "Quand le porteur est sonné, le stimpatch le stimule", price: 50, category: "patch" },
  { name: "Fibripatch", description: "Quand le porteur tombe agonisant, le patch le stabilise", price: 80, category: "patch" },
  { name: "Vigpatch", description: "Le porteur a +1DD à son prochain jet de dégâts Mains nues/AB", price: 100, category: "patch" },
  { name: "Focuspatch", description: "Quand le porteur fait moins de la moitié du max d'un jet de précision, +1D préci", price: 100, category: "patch" },
  { name: "Répercupatch", description: "Quand le porteur reçoit des dégâts, il gagne 1 action immédiate", price: 200, category: "patch" },
  { name: "Vitapatch", description: "Quand le porteur tombe agonisant, le patch le remet à 0 PV", price: 300, category: "patch" }
]

patches.each do |patch|
  InventoryObject.find_or_create_by!(name: patch[:name], category: patch[:category]) do |p|
    p.description = patch[:description]
    p.price = patch[:price]
  end
end

puts "✅ Les patchs ont été ajoutés à la base de données."

puts "Creating statuses..."
statuses = [
  { name: "En forme", description: "En pleine santé", color: "#00FF00" }, # Vert clair
  { name: "Empoisonné", description: "Empoisonné", color: "#7F00FF" }, # Violet
  { name: "Irradié", description: "Irradié par des radiations", color: "#FFD700" }, # Or
  { name: "Agonisant", description: "À l'agonie, proche de la mort", color: "#8B0000" }, # Rouge foncé
  { name: "Mort", description: "Le joueur est mort", color: "#A9A9A9" }, # Gris
  { name: "Inconscient", description: "Inconscient, dans le coma", color: "#808080" }, # Gris foncé
  { name: "Malade", description: "Affection commune", color: "#FF4500" }, # Orange foncé
  { name: "Maladie Virale", description: "Affection commune", color: "#FF4600" },
  { name: "Gravement Malade", description: "Affection grave", color: "#FF4700" },
  { name: "Paralysé", description: "Impossible de bouger", color: "#FF69B4" }, # Rose
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
