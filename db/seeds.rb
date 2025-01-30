puts "Adding new skills..."

# Liste actuelle des compétences
new_skills = [
  { name: "Vitesse", description: "Augmente les déplacements rapides." },
  { name: "Précision", description: "Améliore les tirs à distance." },
  { name: "Esquive", description: "Réduit les chances d'être touché." },
  { name: "Ingénierie", description: "Permet de fabriquer et d'améliorer des objets techniques." },
  { name: "Médecine", description: "Compétence pour soigner les autres." },
  { name: "Résistance Corporelle", description: "Réduit les dégâts subis en fonction du jet de résistance corporelle." }
]

# Liste des nouvelles compétences à ajouter
additional_skills = [
  "Sabre-laser", "Arts martiaux", "Armes blanches", "Lancer", "Tir", "Discrétion", "Habileté",
  "Observation", "Intuition", "Imitation", "Psychologie", "Commandement", "Marchandage",
  "Persuasion", "Dressage", "Saut", "Escalade", "Endurance", "Intimidation", "Natation",
  "Survie", "Nature", "Substances", "Savoir jedi", "Langage", "Astrophysique", "Planètes",
  "Evaluation", "Illégalité", "Pilotage", "Esquive spatiale", "Astrogation", "Tourelles",
  "Jetpack", "Réparation", "Sécurité", "Démolition", "Systèmes", "Contrôle",
  "Sens", "Altération"
]

# Ajouter les nouvelles compétences à la liste existante
additional_skills.each do |skill_name|
  new_skills << { name: skill_name, description: "Description à définir pour #{skill_name}." }
end

# Créer ou mettre à jour les compétences dans la base de données
new_skills.each do |skill|
  Skill.find_or_create_by!(name: skill[:name]) do |s|
    s.description = skill[:description]
  end
end

puts "✅ New skills added successfully!"

puts "Adding new implants..."
# Liste des implants
implants = [
  { name: "Implant de vitalité", price: 400, description: "Implant lvl 1 ajoutant +5 Pvmax temporaires tant que l'implant est porté", rarity: "Commun", category: "implant" },
  { name: "Implant de vitalité +", price: 1000, description: "Implant lvl 2 ajoutant +10 Pvmax temporaires tant que l'implant est porté", rarity: "Unco", category: "implant" },
  { name: "Implant de récupération", price: 600, description: "Implant lvl 1 permettant de récupérer +1PV à chaque début de tour", rarity: "Commun", category: "implant" },
  { name: "Implant de récupération +", price: 1200, description: "Implant lvl 2 permettant de récupérer +2PV à chaque début de tour", rarity: "Unco", category: "implant" },
  { name: "Implant de comm neurale", price: 500, description: "Implant lvl 1 permettant de communiquer par la pensée avec un autre cyborg", rarity: "Commun", category: "implant" }
]

# Création ou mise à jour des implants dans la base de données
implants.each do |implant|
  InventoryObject.find_or_create_by!(name: implant[:name]) do |obj|
    obj.price = implant[:price]
    obj.description = implant[:description]
    obj.rarity = implant[:rarity]
    obj.category = implant[:category]
  end
end

skills = Skill.all
skills.each do |skill|
  # Implant ajoutant +1 à la compétence
  InventoryObject.find_or_create_by!(
    name: "Implant de #{skill.name} +1"
  ) do |object|
    object.price = 200
    object.description = "Ajoute +1 à la compétence #{skill.name} tant que l'implant est porté."
    object.rarity = "Commun"
    object.category = "implant"
  end

  # Implant ajoutant +2 à la compétence
  InventoryObject.find_or_create_by!(
    name: "Implant de #{skill.name} +2"
  ) do |object|
    object.price = 500
    object.description = "Ajoute +2 à la compétence #{skill.name} tant que l'implant est porté."
    object.rarity = "Unco"
    object.category = "implant"
  end

  # Implant ajoutant +1D à la compétence
  InventoryObject.find_or_create_by!(
    name: "Implant de #{skill.name} +1D"
  ) do |object|
    object.price = 1500
    object.description = "Ajoute +1D à la compétence #{skill.name} tant que l'implant est porté."
    object.rarity = "Rare"
    object.category = "implant"
  end
end

puts "✅ New implants added successfully!"

puts "Adding new ingredients..."

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
  { name: "Matière organique", price: 50, description: "Un substrat de matière organique amalgamée", rarity: "Commun" },
  { name: "Dose de bacta", price: 100, description: "Une dose de bacta, cette substance régénératrice utilisée dans les medipacks et cuves à bacta", rarity: "Unco" },
  { name: "Dose de kolto", price: 300, description: "Une dose de kolto, une substance régénératrice rare et très efficace", rarity: "Rare" },
  { name: "Jeu d'éprouvettes", price: 50, description: "Un simple jeu d'éprouvettes pour l'artisanat du biosavant", rarity: "Commun" },
  { name: "Pique chirurgicale", price: 300, description: "Une pique chirurgicale à usage unique pour les manipulations techniques difficiles du biosavant", rarity: "Unco" },
  { name: "Diffuseur aérosol", price: 100, description: "Un diffuseur aérosol à ouverture manuelle ou retardée, pour y mettre des choses méchantes à diffuser dedans", rarity: "Unco" },
  { name: "Matière explosive", price: 200, description: "La matière explosive est une matière malléable et adaptable, qui sert à la fabrication d'explosifs", rarity: "Commun" },
  { name: "Poudre de Zabron", price: 100, description: "La poudre de zabron est issu d'un sable très volatile qui se disperse en de grandes volutes de fumée rose", rarity: "Commun" },
  { name: "Neurotoxine", price: 300, description: "Une substance neurotoxique particulièrement dangereuse", rarity: "Rare" }
]

ingredients.each do |ingredient|
  InventoryObject.find_or_create_by!(name: ingredient[:name], category: "ingredient") do |obj|
    obj.price = ingredient[:price]
    obj.description = ingredient[:description]
    obj.rarity = ingredient[:rarity]
  end
end

# Processors
processors = [
  { name: "Processeur basique (10)", price: 200, description: "Un processeur de base dont la vitesse permettra à la plupart des navordinateurs et droïdes de fonctionner", rarity: "Commun" },
  { name: "Processeur 12", price: 400, description: "Un processeur un peu amélioré, de façon à intégrer quelques fonctions plus poussées", rarity: "Commun" },
  { name: "Processeur 14", price: 600, description: "Un processeur plus puissant dont la vitesse permettra à des systèmes plus complexes de fonctionner", rarity: "Unco" },
  { name: "Processeur 16", price: 1500, description: "Un processeur très puissant qui conviendra pour faire tourner la plupart des systèmes", rarity: "Rare" },
  { name: "Processeur 18", price: 3000, description: "Un processeur rare d'une technologie de pointe dont la puissance énorme permet de gérer presque tout système", rarity: "Rare" },
  { name: "Processeur 20", price: 6000, description: "Un processeur rare et de très haute technologie dont la puissance extrême permet de gérer tout type de système", rarity: "Très rare" }
]

processors.each do |processor|
  InventoryObject.find_or_create_by!(name: processor[:name]) do |obj|
    obj.price = processor[:price]
    obj.description = processor[:description]
    obj.rarity = processor[:rarity]
    obj.category = "processeur"
  end
end

# Animals
animals = [
  { name: "Sang de félin", price: 300, description: "Du sang de félin bien frais pour les expériences scientifiques", rarity: "Unco" },
  { name: "Hormone de rongeur", price: 300, description: "Des hormones spécifiques de rongeurs dédiées à la science", rarity: "Unco" },
  { name: "Cerveau de mammifère aquatique", price: 300, description: "Un cerveau frais disponible pour expérimentation", rarity: "Unco" },
  { name: "Yeux de rapace", price: 300, description: "Des yeux de rapaces conservés pour l'expérimentation scientifique", rarity: "Unco" },
  { name: "Sang de Dragon Krayt", price: 800, description: "Du sang de Dragon Krayt bouillonnant dans une éprouvette", rarity: "Rare" },
  { name: "Sang de Rancor", price: 800, description: "Du sang de Rancor bouillonnant dans une éprouvette", rarity: "Rare" }
]

animals.each do |animal|
  InventoryObject.find_or_create_by!(name: animal[:name]) do |obj|
    obj.price = animal[:price]
    obj.description = animal[:description]
    obj.rarity = animal[:rarity]
    obj.category = "animal"
  end
end

# Plants
plants = [
  { name: "Cardamine", price: 30, description: "Une petite plante commune aux propriétés diurétiques, et toxique à haute dose", rarity: "Commun" },
  { name: "Kava", price: 50, description: "Une plante hallucinogène, aux effets réactifs divers en mélange avec d’autres plantes", rarity: "Commun" },
  { name: "Passiflore", price: 100, description: "Une famille de plantes peu communes, à très haute toxicité", rarity: "Unco" },
  { name: "Nysillin", price: 100, description: "Une famille de plantes peu communes, à vertu thérapeuthique", rarity: "Unco" }
]

plants.each do |plant|
  InventoryObject.find_or_create_by!(name: plant[:name]) do |obj|
    obj.price = plant[:price]
    obj.description = plant[:description]
    obj.rarity = plant[:rarity]
    obj.category = "plante"
  end
end

injections = [
  { name: "Injection d'adrénaline", price: 200, description: "Perd 2 PV mais augmente les compétences de dex de +1D pour 3 tours", rarity: "Unco", category: "injection" },
  { name: "Injection d'hormone de Shalk", price: 300, description: "Perd 2 PV mais augmente les compétences de vig de +1D pour 3 tours", rarity: "Rare", category: "injection" },
  { name: "Injection de phosphore", price: 100, description: "Perd 2 PV mais augmente les compétences de sav de +1D pour 3 tours", rarity: "Unco", category: "injection" },
  { name: "Injection de focusféron", price: 100, description: "Perd 2 PV mais augmente les compétences de perc de +1D pour 3 tours", rarity: "Unco", category: "injection" },
  { name: "Injection de trinitine", price: 50, description: "Regagne +1D PV par tour pour 3 tours, mais -2 toutes comp", rarity: "Unco", category: "injection" },
  { name: "Injection de stimulant", price: 50, description: "Perd 2 PV mais est immunisé au statut désorienté ou sonné 3 tours", rarity: "Unco", category: "injection" },
  { name: "Injection de bio-rage", price: 400, description: "Folie 1D tours, +1DD au CaC, +1 action d’attaque par tour", rarity: "Rare", category: "injection" },
  { name: "Injection tétrasulfurée", price: 500, description: "Ne peut pas passer en statut sonné, inconscient ou agonisant 3 tours", rarity: "Rare", category: "injection" }
]

injections.each do |injection|
  InventoryObject.find_or_create_by!(name: injection[:name]) do |obj|
    obj.price = injection[:price]
    obj.description = injection[:description]
    obj.rarity = injection[:rarity]
    obj.category = injection[:category]
  end
end

chemical_weapons = [
  { name: "Gaz Lacrymogène", price: 50, description: "A le statut désorienté tant qu’il est exposé à l’arme", rarity: "Commun", category: "chimique" },
  { name: "Gaz Souffre", price: 100, description: "Perd 1D PV Ignore def / tour tant qu’il est exposé", rarity: "Commun", category: "chimique" },
  { name: "Gaz Empoisonné", price: 300, description: "Perd 2D PV Ignore def / tour tant qu’il est exposé + Empoisonné", rarity: "Unco", category: "chimique" },
  { name: "Gaz Neurolax", price: 500, description: "Perd 2D PV Ign def / tour tant qu’il est exposé + Tue les -20PVmax", rarity: "Rare", category: "chimique" }
]

chemical_weapons.each do |weapon|
  InventoryObject.find_or_create_by!(name: weapon[:name]) do |obj|
    obj.price = weapon[:price]
    obj.description = weapon[:description]
    obj.rarity = weapon[:rarity]
    obj.category = weapon[:category]
  end
end

poisons = [
  { name: "Laxatif", price: 30, description: "Jet de vig pour résister au poison : 15 / Effets : -1DD au CaC et -1D précision à distance, -1PV / tour, 3/12 se chie dessus", rarity: "Commun", category: "poison" },
  { name: "Tranquilisant", price: 50, description: "Jet de vig pour résister au poison : 15 / Effets : -1D à tous ses jets, -1PV / tour, 1/12 s'endort", rarity: "Commun", category: "poison" },
  { name: "Somnifère", price: 50, description: "Jet de vig pour résister au poison : 20 / Effets : -1D à tous ses jets, -2PV / tour, 2/12 s'endort, 10/12 si 25PVmax", rarity: "Unco", category: "poison" },
  { name: "Poison", price: 100, description: "Jet de vig pour résister au poison : 15 / Effets : -1DPV / tour, 1/12 tombe inconscient", rarity: "Commun", category: "poison" },
  { name: "Poison neurotoxique", price: 200, description: "Jet de vig pour résister au poison : 20 / Effets : -1DPV / tour, 2/12 tombe inconscient", rarity: "Unco", category: "poison" },
  { name: "Poison foudroyant", price: 300, description: "Jet de vig pour résister au poison : 25 / Effets : -2DPV / tour, 4/12 tombe inconscient, 1/12 meurt", rarity: "Rare", category: "poison" },
  { name: "Stimulateur mnémonique", price: 300, description: "Jet de vig pour résister : 20 / Rend une personne très volubile, proche d'un sérum de vérité. +1D Comm, Intim, Psy sur elle", rarity: "Rare", category: "poison" }
]

poisons.each do |poison|
  InventoryObject.find_or_create_by!(name: poison[:name]) do |obj|
    obj.price = poison[:price]
    obj.description = poison[:description]
    obj.rarity = poison[:rarity]
    obj.category = poison[:category]
  end
end

repair_kit = InventoryObject.find_or_create_by!(name: "Kit de réparation", category: "soins", description: "Répare un droïde.")

puts "✅ New objects added successfully!"

puts "Adding new status..."

Status.create!(name: "Folie", description: "Ne se contrôle plus et attaque le plus proche", color: "#FF69B4")

puts "✅ New status added successfully!"
