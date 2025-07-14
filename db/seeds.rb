puts "Creating groups..."
group1 = Group.find_or_create_by!(name: "MJ", description: "Le groupe des Maîtres du Jeu. Prosternez vous.")
group2 = Group.find_or_create_by!(name: "PNJ", description: "Le groupe des marchands et auxiliaires de jeu")
group3 = Group.find_or_create_by!(name: "PJ", description: "Les joueurs jouent au jeu")
group4 = Group.find_or_create_by!(name: "Hackers", description: "Les hackers peuvent hacker les données des autres")

puts "Creating races..."
races_data = YAML.load_file(Rails.root.join('config/catalogs/races.yml'))
races_data.each do |race_data|
  Race.find_or_create_by!(name: race_data['name']) do |r|
    r.description = race_data['description']
  end
end

puts "Creating classes..."
classes_data = YAML.load_file(Rails.root.join('config/catalogs/classes.yml'))
classes_data.each do |class_data|
  ClassePerso.find_or_create_by!(name: class_data['name']) do |c|
    c.description = class_data['description']
  end
end

# Helper pour trouver une race par sa key
def find_race_by_key(key)
  races_data = YAML.load_file(Rails.root.join('config/catalogs/races.yml'))
  race_data = races_data.find { |r| r['key'] == key.to_s }
  Race.find_by(name: race_data['name']) if race_data
end

# Helper pour trouver une classe par sa key
def find_classe_by_key(key)
  classes_data = YAML.load_file(Rails.root.join('config/catalogs/classes.yml'))
  class_data = classes_data.find { |c| c['key'] == key.to_s }
  ClassePerso.find_by(name: class_data['name']) if class_data
end

puts "Creating statuses..."
statuses_data = YAML.load_file(Rails.root.join('config/catalogs/statuses.yml'))
statuses_data.each do |status_data|
  Status.find_or_create_by!(name: status_data['name']) do |s|
    s.description = status_data['description']
    s.color = status_data['color']
  end
end

puts "Creating the users and assigning them to the corresponding groups, races, and classes..."

# Vérification pour le MJ
existing_mj = User.find_by("LOWER(username) = ?", "mj")
puts "MJ existant trouvé : #{existing_mj ? existing_mj.username : 'Aucun'}"

unless existing_mj
  puts "Création du MJ..."
  User.create!(
    username: "MJ",
    email: "mj@rpg.com",
    password: "adminsw",
    hp_max: 1000,
    hp_current: 1000,
    credits: 100000,
    group: group1
  )
  puts "MJ créé avec succès"
else
  puts "MJ déjà existant, passage..."
end

players = [
  { username: "Jarluc", email: "jarluc@rpg.com", race_key: "human", classe_key: "senator", hp_max: 33, hp_current: 33, shield_max: 0, shield_current: 0, echani_shield_max: 0, echani_shield_current: 0, credits: 31650 },
  { username: "Kaey Noa", email: "kay@rpg.com", race_key: "kaminoan", classe_key: "bio_savant", hp_max: 26, hp_current: 26, shield_max: 50, shield_current: 50, echani_shield_max: 50, echani_shield_current: 0, credits: 520 },
  { username: "Nuok", email: "nuok@rpg.com", race_key: "codruji", classe_key: "autodidact", hp_max: 38, hp_current: 38, shield_max: 0, shield_current: 0, echani_shield_max: 0, echani_shield_current: 0, credits: 1110 },
  { username: "Pluto", email: "pluto@rpg.com", race_key: "human", classe_key: "mercenary", hp_max: 34, hp_current: 34, shield_max: 50, shield_current: 50, echani_shield_max: 0, echani_shield_current: 0, credits: 0 },
  { username: "Viggo", email: "viggo@rpg.com", race_key: "toydarian", classe_key: "cyber_engineer", hp_max: 22, hp_current: 22, shield_max: 50, echani_shield_max: 0, echani_shield_current: 0, credits: 14850 },
  { username: "Mas Tandor", email: "mas@rpg.com", race_key: "clawdite", classe_key: "smuggler", hp_max: 21, hp_current: 21, shield_max: 20, shield_current: 20, echani_shield_max: 30, echani_shield_current: 30, credits: 8120 }
]

players.each do |player_attrs|
  # Recherche insensible à la casse
  existing_user = User.find_by("LOWER(username) = ?", player_attrs[:username].downcase)
  puts "Utilisateur #{player_attrs[:username]} existant : #{existing_user ? 'Oui' : 'Non'}"
  
  unless existing_user
    puts "Création de #{player_attrs[:username]}..."
    begin
      user = User.create!(
        username: player_attrs[:username],
        email: player_attrs[:email],
        password: "password",
        group: group3,
        race: find_race_by_key(player_attrs[:race_key]),
        classe_perso: find_classe_by_key(player_attrs[:classe_key]),
        hp_max: player_attrs[:hp_max],
        hp_current: player_attrs[:hp_current],
        shield_max: player_attrs[:shield_max],
        shield_current: player_attrs[:shield_current],
        echani_shield_max: player_attrs[:echani_shield_max],
        echani_shield_current: player_attrs[:echani_shield_current],
        credits: player_attrs[:credits]
      )
      # ✅ Utiliser set_status pour éviter les doublons potentiels
      user.set_status("En forme")
      puts "#{player_attrs[:username]} créé avec succès"
    rescue ActiveRecord::RecordInvalid => e
      puts "Erreur lors de la création de #{player_attrs[:username]}: #{e.message}"
      # Vérifier s'il y a des doublons
      puts "Utilisateurs avec username similaire: #{User.where("username ILIKE ?", "%#{player_attrs[:username]}%").pluck(:username, :email)}"
      puts "Utilisateurs avec email similaire: #{User.where("email ILIKE ?", "%#{player_attrs[:email]}%").pluck(:username, :email)}"
      raise e
    end
  else
    puts "#{player_attrs[:username]} déjà existant, passage..."
  end
end

puts "Adding new skills..."

puts "🛠️ Création des caractéristiques..."
skills_data = YAML.load_file(Rails.root.join('config/catalogs/skills.yml'))

# Crée les caractéristiques
skills_data['caracteristics'].each do |carac_data|
  Carac.find_or_create_by!(name: carac_data['name'])
end

puts "✅ Caractéristiques créées."

puts "📌 Création et mise à jour des compétences..."

# Crée les compétences avec leurs associations aux caractéristiques
skills_data['skills'].each do |skill_data|
  carac = skill_data['carac'] ? Carac.find_by(name: skill_data['carac']) : nil
  Skill.find_or_create_by!(name: skill_data['name']) do |s|
    s.description = skill_data['description'] || ""
    s.carac = carac
  end
end

puts "✅ Compétences créées ou mises à jour."

puts "✅ New skills added successfully!"

puts "📦 Création des objets d'inventaire depuis le fichier YAML..."

# Charge les objets depuis le fichier YAML
inventory_objects_data = YAML.load_file(Rails.root.join('config/catalogs/inventory_objects.yml'))

# Crée tous les objets par catégorie
inventory_objects_data.each do |category, items|
  items.each do |item_data|
    InventoryObject.find_or_create_by!(name: item_data['name']) do |obj|
      obj.category = item_data['category']
      obj.price = item_data['price']
      obj.description = item_data['description']
      obj.rarity = item_data['rarity']
    end
  end
end

# Génère les implants dynamiques pour chaque compétence
puts "📦 Création des implants dynamiques par compétence..."
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

puts "✅ Objets d'inventaire créés avec succès!"

puts "🍷 Création des alcools depuis le fichier drinks.yml..."

# Charge les alcools depuis le fichier YAML
drinks_data = YAML.load_file(Rails.root.join('config/catalogs/drinks.yml'))['drinks']

# Crée ou met à jour les alcools en utilisant catalog_id comme identifiant unique
drinks_data.each do |drink_data|
  # Cherche par catalog_id (unique et stable) au lieu du nom (qui peut changer)
  drink = InventoryObject.find_or_initialize_by(catalog_id: drink_data['id'])
  drink.update!(
    name: drink_data['name'],
    category: 'drinks',
    price: drink_data['price'],
    description: drink_data['description'],
    rarity: 'Commun'
  )
end

puts "✅ Alcools créés avec succès!"

puts "Adding new base..."

Headquarter.find_or_create_by!(name: "Nom de la base", location: "Planète inconnue", credits: 0, description: "Aucune description pour l'instant.")

puts "✅ New base added successfully!"

puts "📦 Création des bâtiments par défaut..."

headquarter = Headquarter.first_or_create!(name: "Base Célestiale", location: "Mobile - Bordure Extérieure", credits: 0, description: "Une mystérieuse base très ancienne")

if Building::BUILDING_DATA.nil?
  puts "⚠️ Erreur : Impossible de charger les données des bâtiments !"
  exit
end

Building::BUILDING_DATA.each do |building_type, levels|
  levels.each do |level, data|
    level = level.to_i 

    building = headquarter.buildings.find_or_initialize_by(name: data["name"])

    building.update!(
      level: 0,
      description: data["description"],
      price: data["price"],
      category: building_type,
      properties: data["properties"] || {}
    )

    puts "✅ Bâtiment ajouté : #{building.name} (Niveau #{building.level})"
  end
end

puts "✅ Bâtiments créés avec succès."

puts "📦 Création des systèmes de défense..."

defenses_data = YAML.load_file(Rails.root.join('config/catalogs/defenses.yml'))
defenses_data.each do |defense_data|
  Defense.find_or_create_by!(name: defense_data['name']) do |d|
    d.description = defense_data['description']
    d.price = defense_data['price']
    d.bonus = defense_data['bonus']
  end
end

puts "✅ Systèmes de défense ajoutés avec succès."

puts "📦 Création des gènes..."

require_relative "seeds/load_genes"

puts "✔️ Tous les gènes ont été chargés avec succès."

