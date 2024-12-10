puts "Reset the database..."

# Supprimer les dépendances
UserSkill.destroy_all
UserInventoryObject.destroy_all
UserStatus.destroy_all
Transaction.destroy_all
Holonew.destroy_all

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
User.create!(username: "MJ", email: "mj@rpg.com", password: "adminsw", hp_max: 1000, hp_current: 1000, credits: 100000, group: group1)

players = [
  { username: "Jarluc", email: "jarluc@rpg.com", race: human, classe_perso: senator, hp_max: 33, hp_current: 33, shield_max: 0, shield_current: 0, echani_shield_max: 0, echani_shield_current: 0, credits: 31650 },
  { username: "Kaey Noah", email: "kay@rpg.com", race: kaminoan, classe_perso: bio_savant, hp_max: 26, hp_current: 26, shield_max: 50, shield_current: 50, echani_shield_max: 50, echani_shield_current: 0, credits: 520 },
  { username: "Nuok", email: "nuok@rpg.com", race: codruji, classe_perso: autodidact, hp_max: 38, hp_current: 38, shield_max: 0, shield_current: 0, echani_shield_max: 0, echani_shield_current: 0, credits: 1110 },
  { username: "Pluto", email: "pluto@rpg.com", race: human, classe_perso: mercenary, hp_max: 34, hp_current: 34, shield_max: 50, shield_current: 50, echani_shield_max: 0, echani_shield_current: 0, credits: 0 },
  { username: "Viggo", email: "viggo@rpg.com", race: toydarian, classe_perso: cyber_engineer, hp_max: 22, hp_current: 22, shield_max: 50, echani_shield_max: 0, echani_shield_current: 0, credits: 14850 },
  { username: "Mas Tandor", email: "mas@rpg.com", race: clawdite, classe_perso: smuggler, hp_max: 21, hp_current: 21, shield_max: 20, shield_current: 20, echani_shield_max: 30, echani_shield_current: 30, credits: 8120 }
]

puts "Creating healing inventory objects..."
inventory_objects = [
  { name: "Medipack", category: "soins", price: 50, description: "Redonne en PV le jet de médecine du soigneur divisé par deux.", rarity: "Commun" },
  { name: "Medipack +", category: "soins", price: 200, description: "Redonne en PV le jet de médecine du soigneur divisé par deux +1D", rarity: "Unco" },
  { name: "Medipack Deluxe", category: "soins", price: 500, description: "Redonne en PV le plein jet de médecine du soigneur", rarity: "Rare" },
  { name: "Antidote", category: "soins", price: 200, description: "Soigne le statut empoisonné, +1D PV", rarity: "Unco" },
  { name: "Extrait de Nysillin", category: "soins", price: 150, description: "Plante soignante de Félucia: +2D PV immédiat en action de soutien", rarity: "Unco" },
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

puts "Adding inventory objects of category 'ingredient'..."

ingredients = [
  { name: "Composant", price: 10, description: "Une pièce basique pour fabriquer ou réparer des objets techniques divers. Se trouve partout", rarity: "Commun" },
  { name: "Transmetteur", price: 50, description: "Le transmetteur est une pièce commune qui permet la transmission d'informations par ondes", rarity: "Commun" },
  { name: "Répartiteur", price: 50, description: "Le répartiteur est une pièce commune qui assure la redistribution de l'énergie", rarity: "Commun" },
  { name: "Répercuteur", price: 100, description: "Le répercuteur est une pièce commune qui permet d'amorcer des systèmes complexes", rarity: "Commun" },
  { name: "Circuit de retransmission", price: 200, description: "Fabriqué par le fabricant à base de 2 compos et 1 transmetteur, le circuit permet d'améliorer la connectique", rarity: "Commun" },
  { name: "Répartiteur fuselé", price: 200, description: "Fabriqué par le fabricant à base de 2 compos et 1 répartiteur, le rép. fuselé redistribue mieux l'énergie", rarity: "Commun" },
  { name: "Convecteur thermique", price: 300, description: "Le convecteur thermique est une pièce peu commune qui a pour fonction la concentration d'énergie", rarity: "Unco" },
  { name: "Senseur", price: 200, description: "Le senseur est une pièce peu commune qui a de multiples paramètres de détection par balayage d'ondes", rarity: "Unco" },
  { name: "Fuseur", price: 400, description: "Le fuseur est une pièce peu commune qui sert à fusionner des particules instables d'énergie", rarity: "Unco" },
  { name: "Propulseur", price: 400, description: "Le propulseur est une pièce peu commune dédiée aux systèmes de propulsion", rarity: "Unco" },
  { name: "Vibro-érecteur", price: 500, description: "Fabriqué avec 2 compos + 1 répercuteur + 1 circ de retr + 1 rép fuselé, sert à activer des puissants systèmes", rarity: "Unco" },
  { name: "Commandes", price: 1000, description: "Les commandes sont une pièce rare qui consiste en une interface de contrôle de systèmes complexes", rarity: "Rare" },
  { name: "Injecteur de photon", price: 2000, description: "L'injecteur de photon est une pièce rare qui sert à la transmission d'énergie dans la technologie de pointe", rarity: "Rare" },
  { name: "Chrysalis", price: 5000, description: "La chrysalis est une pièce très rare, qui catalyse l'énergie du vide pour l'alimentation en énergie", rarity: "Très rare" },
  { name: "Vibreur", price: 200, description: "Le vibreur est une pièce commune qui concentre l'énergie par émission d'ondes vibratoires", rarity: "Commun" },
  { name: "Micro-générateur", price: 300, description: "Le micro-générateur est une pièce commune qui assure l'apport en énergie dans la micro-ingénierie", rarity: "Commun" },
  { name: "Synthé-gilet", price: 200, description: "Nécessaire pour crafter différents types d'améliorations d'armures", rarity: "Commun" },
  { name: "Interface cyber", price: 500, description: "L'interface cyber est une pièce peu commune qui sert à créer une interface homme / machine", rarity: "Unco" },
  { name: "Pile à protons", price: 800, description: "La pile à protons une pièce rare qui sert à capter les particules de protons environnantes", rarity: "Rare" },
  { name: "Lingot de Phrik", price: 500, description: "Le lingot de phrik est un échantillon peu commun d'un métal résistant", rarity: "Unco" },
  { name: "Filet de Lommite", price: 1000, description: "Le filet de lommite est un échantillon rare d'un métal très résistant", rarity: "Rare" },
  { name: "Lingot de Duracier", price: 3000, description: "Le lingot de duracier est un alliage très rare et extrêmement résistant", rarity: "Très rare" },
  { name: "Fiole", price: 30, description: "Un contenant pour diverses préparations de potions et poisons", rarity: "Commun" },
  { name: "Matière organique", price: 80, description: "Un substras de matière organique amalgamée", rarity: "Commun" },
  { name: "Dose de bacta", price: 100, description: "Une dose de bacta, cette substance régénératrice utilisée dans les medipacks et cuves à bacta", rarity: "Unco" },
  { name: "Dose de kolto", price: 300, description: "Une dose de kolto, une substance régénératrice rare et très efficace", rarity: "Rare" },
  { name: "Jeu d'éprouvettes", price: 50, description: "Un simple jeu d'éprouvettes pour l'artisanat du biosavant", rarity: "Commun" },
  { name: "Pique chirurgicale", price: 300, description: "Une pique chirurgicale à usage unique pour les manipulations techniques difficiles du biosavant", rarity: "Unco" },
  { name: "Diffuseur aérosol", price: 100, description: "Un diffuseur aérosol à ouverture manuelle ou retardée, pour y mettre des choses méchantes à diffuser dedans", rarity: "Unco" },
  { name: "Matière explosive", price: 200, description: "La matière explosive est une matière malléable et adaptable, qui sert à la fabrication d'explosifs", rarity: "Commun" },
  { name: "Poudre de Zabron", price: 100, description: "La poudre de zabron est issu d'un sable très volatile qui se disperse en de grandes volutes de fumée rose", rarity: "Commun" },
  { name: "Cardamine", price: 30, description: "Une petite plante commune aux propriétés diurétiques, et toxique à haute dose", rarity: "Commun" },
  { name: "Kava", price: 50, description: "Une plante hallucinogène, aux effets réactifs divers en mélange avec d’autres plantes", rarity: "Commun" },
  { name: "Passiflore", price: 100, description: "Une famille de plantes peu commune, à très haute toxicité", rarity: "Unco" },
  { name: "Neurotoxique", price: 300, description: "Une substance neurotoxique particulièrement dangereuse", rarity: "Rare" },
  { name: "Processeur basique (10)", price: 200, description: "Un processeur de base dont la vitesse permettra à la plupart des navordinateurs et droïdes de fonctionner", rarity: "Commun" },
  { name: "Processeur 12", price: 400, description: "Un processeur un peu amélioré, de façon à intégrer quelques fonctions plus poussées", rarity: "Commun" },
  { name: "Processeur 14", price: 600, description: "Un processeur plus puissant dont la vitesse permettra à des systèmes plus complexes de fonctionner", rarity: "Unco" },
  { name: "Processeur 16", price: 1500, description: "Un processeur très puissant qui conviendra pour faire tourner la plupart des systèmes", rarity: "Rare" },
  { name: "Processeur 18", price: 3000, description: "Un processeur rare d'une technologie de pointe dont la puissance énorme permet de gérer presque tout système", rarity: "Rare" },
  { name: "Processeur 20", price: 6000, description: "Un processeur rare et de très haute technologie dont la puissance extrême permet de gérer tout type de système", rarity: "Très rare" }
]

ingredients.each do |ingredient|
  InventoryObject.create!(ingredient.merge(category: "ingredient"))
end

puts "Finished adding inventory objects of category 'ingredient'."

puts "Creating statuses..."
statuses = [
  { name: "En forme", description: "En pleine santé", color: "#1EDD88" }, # Vert clair
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
skills = [
  { name: "Médecine", description: "Compétence pour soigner les autres." },
  { name: "Résistance Corporelle", description: "Réduit les dégâts subis en fonction du jet de résistance corporelle." },
  { name: "Ingénierie", description: "Compétence pour crafter des trucs" },
]

skills.each do |skill|
  Skill.find_or_create_by!(name: skill[:name]) do |s|
    s.description = skill[:description]
  end
end

puts "Creating pets..."

Pet.create!(
  name: "Jiya",
  race: "Jawa",
  hp_current: 20,
  hp_max: 20,
  res_corp: 2,
  res_corp_bonus: 1,
  speed: 5,
  damage_1: 5,
  damage_2: 5,
  accuracy: 6,
  dodge: 5,
  weapon_1: "Sabre Laser",
  weapon_2: "Fusil Blaster +2"
)

Pet.create!(
  name: "R4-X3",
  race: "Astromex",
  hp_current: 12,
  hp_max: 12,
  res_corp: 1,
  res_corp_bonus: 2,
  speed: 2,
  damage_1: 6,
  accuracy: 3,
  dodge: 1,
  weapon_1: "Lance-Flammes",
)

Pet.create!(
  name: "Elenoa",
  race: "Cathar",
  hp_current: 18,
  hp_max: 18,
  res_corp: 1,
  res_corp_bonus: 2,
  speed: 8,
  damage_1: 4,
  damage_2: 5,
  accuracy: 7,
  dodge: 8,
  weapon_1: "Griffes",
  weapon_2: "Fusil Blaster Wilson"
)

puts "Task completed!"
