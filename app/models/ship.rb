class Ship < ApplicationRecord
  belongs_to :group
  belongs_to :parent_ship, class_name: 'Ship', optional: true
  has_many :child_ships, class_name: 'Ship', foreign_key: 'parent_ship_id', dependent: :nullify

  has_one_attached :image

  has_many :ships_skills, dependent: :destroy
  has_many :skills, through: :ships_skills

  has_many :ship_objects, dependent: :destroy

  has_many :ship_weapons, dependent: :destroy

  has_many :crew_members, dependent: :destroy

  enum scale: {
    very_small: 0,
    small: 1,
    medium: 2,
    big: 3,
    very_big: 4,
    gigantic: 5
  }

  # Configuration des armes prédéfinies
  PREDEFINED_WEAPONS = {
    "Canon blaster" => {
      price: 500,
      damage_mastery: 5,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: nil
    },
    "Canon lourd" => {
      price: 1500,
      damage_mastery: 6,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: -1,
      special: nil
    },
    "Canon plasmique" => {
      price: 5000,
      damage_mastery: 6,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: nil
    },
    "Canon Magma" => {
      price: 10000,
      damage_mastery: 7,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Traversant, -3PB/tir"
    },
    "Canon à ions" => {
      price: 1500,
      damage_mastery: 5,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Peut ioniser les commandes du vaisseau adverse"
    },
    "Lance-Missiles à concussion" => {
      price: 8000,
      damage_mastery: 6,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Arme à munitions limitées",
      weapon_type: 'missile'
    },
    "Lance-Torpilles à protons" => {
      price: 10000,
      damage_mastery: 8,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Arme à munitions limitées",
      weapon_type: 'torpille'
    },
    "Tourelle pulso-blaster" => {
      price: 1000,
      damage_mastery: 4,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: nil,
      weapon_type: 'tourelle'
    },
    "Tourelle lourde" => {
      price: 2000,
      damage_mastery: 5,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: -1,
      special: nil,
      weapon_type: 'tourelle'
    },
    "Tourelle plasmique" => {
      price: 4000,
      damage_mastery: 5,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: nil,
      weapon_type: 'tourelle'
    },
    "Tourelle à ions" => {
      price: 1500,
      damage_mastery: 4,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Ionisant",
      weapon_type: 'tourelle'
    }
  }.freeze

  # Configuration des munitions
  AMMUNITION_CONFIG = {
    'missile' => { name: 'Missile à concussion', price: 500 },
    'torpille' => { name: 'Torpille à protons', price: 600 }
  }.freeze

  # Configuration des équipements spéciaux
  SPECIAL_EQUIPMENT = {
    "Rayon tracteur" => {
      price: 500,
      description: "Faisceau magnétique pour attirer des objets et petits vaisseaux",
      special: "Peut attirer des objets ou petits vaisseaux",
      weapon_type: 'special'
    },
    "Scanner de cargaison" => {
      price: 800,
      description: "Permet de scanner la cargaison d'un autre vaisseau",
      special: "Révèle la cargaison d'un vaisseau ciblé",
      weapon_type: 'special'
    },
    "Scanner d'activité" => {
      price: 1000,
      description: "Permet de scanner l'activité et les êtres vivants d'un autre vaisseau",
      special: "Détecte les êtres vivants et activités à bord",
      weapon_type: 'special'
    },
    "Scanner de planète" => {
      price: 500,
      description: "Fournit des informations sur l'atmosphère, les ressources, et la vie d'une planète proche",
      special: "Analyse complète des planètes",
      weapon_type: 'special'
    },
    "Onduleur de bouclier" => {
      price: 1000,
      description: "Permet de concentrer l'énergie des boucliers sur l'avant, le côté ou l'arrière du vaisseau",
      special: "Redistribution des boucliers directionnels",
      weapon_type: 'special'
    },
    "Module de camouflage" => {
      price: 1500,
      description: "Rend le vaisseau invisible aux senseurs pour quelques secondes",
      special: "Invisibilité temporaire aux senseurs",
      weapon_type: 'special'
    },
    "Extracteur de minerai" => {
      price: 1200,
      description: "Équipement pour extraire des ressources minérales",
      special: "Extraction de minerais depuis l'espace ou planètes",
      weapon_type: 'special'
    },
    "Balise de localisation" => {
      price: 200,
      description: "Drone-Balise pour marquer discrètement un autre vaisseau pour suivre sa position à distance",
      special: "Marquage de vaisseaux pour suivi",
      weapon_type: 'special',
      quantity_max: 10,
      usage_unique: true
    },
    "Contre-mesures" => {
      price: 200,
      description: "Contre-mesure pour réduire la précision des missiles et torpilles ennemies",
      special: "Réduction précision missiles/torpilles ennemis",
      weapon_type: 'special',
      quantity_max: 10,
      usage_unique: true
    }
  }.freeze

  validates :name, presence: true
  validates :model, presence: true
  validate :used_capacity_cannot_exceed_capacity
  validates :thruster_level, :hull_level, :circuits_level, :shield_system_level, 
            inclusion: { in: 0..3, message: "doit être entre 0 et 3" }
  validates :hp_max_upgrades, numericality: { greater_than_or_equal_to: 0 }
  validates :astromech_droids, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }

  before_create :set_initial_hp
  before_validation :set_scale_and_capacity_from_size
  after_save :update_parent_used_capacity, if: :saved_change_to_parent_ship_id?

  # Méthodes pour les améliorations
  def upgrade_info(type)
    SHIP_UPGRADES[type.to_sym]
  end

  def current_upgrade_level(type)
    send("#{type}_level")
  end

  def next_upgrade_available?(type)
    current_level = current_upgrade_level(type)
    current_level < 3 && SHIP_UPGRADES[type.to_sym][:levels][current_level + 1].present?
  end

  def next_upgrade_info(type)
    return nil unless next_upgrade_available?(type)
    next_level = current_upgrade_level(type) + 1
    SHIP_UPGRADES[type.to_sym][:levels][next_level]
  end

  def upgrade_price(type)
    next_upgrade_info(type)&.dig(:price) || 0
  end

  def can_upgrade?(type, user_credits)
    next_upgrade_available?(type) && user_credits >= upgrade_price(type)
  end

  def upgrade!(type)
    return false unless next_upgrade_available?(type)
    
    # Récupérer les informations avant l'upgrade
    old_level = current_upgrade_level(type)
    new_level = old_level + 1
    
    # Mettre à jour le niveau
    send("#{type}_level=", new_level)
    
    # Mettre à jour la ship_skill correspondante
    update_ship_skill_for_upgrade(type, old_level, new_level)
    
    save!
  end

  def current_upgrade_info(type)
    current_level = current_upgrade_level(type)
    SHIP_UPGRADES[type.to_sym][:levels][current_level]
  end

  def upgrade_bonuses
    bonuses = {}
    SHIP_UPGRADES.each do |type, config|
      current_level = current_upgrade_level(type)
      level_info = config[:levels][current_level]
      if level_info && level_info[:bonus] != "0"
        bonuses[type] = level_info[:bonus]
      end
    end
    bonuses
  end

  # Méthodes pour les senseurs
  def sensor_current_level(sensor_skill_name)
    skill = Skill.find_by(name: sensor_skill_name)
    return 0 unless skill
    
    ships_skill = ships_skills.find_by(skill: skill)
    return 0 unless ships_skill
    
    # Convertir mastery/bonus en niveau total
    mastery = ships_skill.mastery || 0
    bonus = ships_skill.bonus || 0
    
    # Formule : niveau = mastery * 3 + bonus
    mastery * 3 + bonus
  end

  def sensor_upgrade_price(sensor_skill_name)
    current_level = sensor_current_level(sensor_skill_name)
    (current_level + 1) * 200
  end

  def sensor_next_bonus_string(sensor_skill_name)
    current_level = sensor_current_level(sensor_skill_name)
    next_level = current_level + 1
    
    next_mastery = next_level / 3
    next_bonus = next_level % 3
    
    if next_mastery == 0
      "+#{next_bonus}"
    elsif next_bonus == 0
      "+#{next_mastery}D"
    else
      "+#{next_mastery}D+#{next_bonus}"
    end
  end

  def sensor_current_bonus_string(sensor_skill_name)
    current_level = sensor_current_level(sensor_skill_name)
    return "0" if current_level == 0
    
    current_mastery = current_level / 3
    current_bonus = current_level % 3
    
    if current_mastery == 0
      "+#{current_bonus}"
    elsif current_bonus == 0
      "+#{current_mastery}D"
    else
      "+#{current_mastery}D+#{current_bonus}"
    end
  end

  def can_upgrade_sensor?(sensor_skill_name, user_credits)
    price = sensor_upgrade_price(sensor_skill_name)
    user_credits >= price
  end

  def upgrade_sensor!(sensor_skill_name)
    skill = Skill.find_by(name: sensor_skill_name)
    return false unless skill
    
    ships_skill = ships_skills.find_by(skill: skill)
    return false unless ships_skill
    
    current_level = sensor_current_level(sensor_skill_name)
    next_level = current_level + 1
    
    new_mastery = next_level / 3
    new_bonus = next_level % 3
    
    ships_skill.update!(mastery: new_mastery, bonus: new_bonus)
    true
  end

  # Méthodes pour les systèmes de survie (hp_max)
  def hp_max_upgrade_count
    hp_max_upgrades || 0
  end

  def hp_max_upgrade_price
    current_upgrades = hp_max_upgrade_count
    (current_upgrades + 1) * 200
  end

  def can_upgrade_hp_max?(user_credits)
    price = hp_max_upgrade_price
    user_credits >= price
  end

  def upgrade_hp_max!
    increment!(:hp_max, 1)
    increment!(:hp_max_upgrades, 1)
    true
  end

  # Méthodes pour les armes
  def main_weapon
    ship_weapons.find_by(weapon_type: 'main')
  end

  def secondary_weapon
    ship_weapons.find_by(weapon_type: 'secondary')
  end

  def available_weapons
    excluded_ids = [main_weapon&.id, secondary_weapon&.id, torpedo_launcher&.id, missile_launcher&.id].compact
    ship_weapons.where(weapon_type: ['purchased', 'original']).where.not(id: excluded_ids)
  end

  def can_buy_weapon?(weapon_name, user_credits)
    weapon_config = PREDEFINED_WEAPONS[weapon_name]
    return false unless weapon_config
    user_credits >= weapon_config[:price]
  end

  def buy_weapon!(weapon_name)
    weapon_config = PREDEFINED_WEAPONS[weapon_name]
    return false unless weapon_config

    ship_weapons.create!(
      name: weapon_name,
      weapon_type: 'purchased',
      damage_mastery: weapon_config[:damage_mastery],
      damage_bonus: weapon_config[:damage_bonus],
      aim_mastery: weapon_config[:aim_mastery],
      aim_bonus: weapon_config[:aim_bonus],
      special: weapon_config[:special],
      price: weapon_config[:price]
    )
    true
  end

  def install_weapon!(weapon_id, slot)
    weapon = ship_weapons.find(weapon_id)
    return false unless weapon
    return false unless ['main', 'secondary', 'torpille', 'missile'].include?(slot)
    
    # Vérification spéciale pour les torpilles
    if slot == 'torpille' && !can_install_torpedo_launcher?
      return false
    end

    # Désinstaller l'arme actuelle du slot
    current_weapon = ship_weapons.find_by(weapon_type: slot)
    if current_weapon
      current_weapon.update!(weapon_type: current_weapon.price > 0 ? 'purchased' : 'original')
    end

    # Installer la nouvelle arme
    weapon.update!(weapon_type: slot)
    
    # Activer les booléens pour les lanceurs
    if slot == 'torpille'
      update!(torpilles: true)
    elsif slot == 'missile'
      update!(missiles: true)
    end
    
    true
  end

  def uninstall_weapon!(slot)
    weapon = ship_weapons.find_by(weapon_type: slot)
    return false unless weapon

    # Pour les lanceurs spéciaux, désactiver les booléens
    if slot == 'torpille'
      update!(torpilles: false)
    elsif slot == 'missile'
      update!(missiles: false)
    end

    weapon.update!(weapon_type: weapon.price > 0 ? 'purchased' : 'original')
    true
  end

  def sell_weapon!(weapon_id)
    weapon = ship_weapons.find(weapon_id)
    return false unless weapon
    return false if weapon.price == 0 # Ne peut pas vendre les armes originales
    return false if ['main', 'secondary'].include?(weapon.weapon_type) # Ne peut pas vendre les armes principales/secondaires installées

    # Pour les lanceurs installés, désactiver les booléens
    if weapon.weapon_type == 'torpille'
      update!(torpilles: false)
    elsif weapon.weapon_type == 'missile'
      update!(missiles: false)
    end

    sell_price = weapon.price / 2
    weapon.destroy!
    sell_price
  end

  def weapon_sell_price(weapon_id)
    weapon = ship_weapons.find(weapon_id)
    return 0 unless weapon
    return 0 if weapon.price == 0
    weapon.price / 2
  end

  def status_labels
    labels = []
    labels << "Écrans désactivés" if shields_disabled
    labels << "Commandes ionisées" if controls_ionized
    labels << "Arme endommagée" if weapon_damaged
    labels << "Propulseurs touchés" if thrusters_damaged
    labels << "Hyperdrive HS" if hyperdrive_broken
    labels << "Dépressurisation" if depressurized
    labels << "Vaisseau détruit" if ship_destroyed
    labels = ["Intact"] if labels.empty?
    labels
  end

  # Retourne la capacité occupée si ce vaisseau est embarqué
  def embarked_capacity
    case scale.to_sym
    when :very_small then 1
    when :small then 2
    when :medium then 6
    when :big then 14
    else 0
    end
  end

  # Peut-il être embarqué ?
  def can_be_embarked?
    return false if parent_ship_id.present? # Ne peut pas être embarqué s'il est déjà embarqué
    return false if scale.to_sym == :very_big || scale.to_sym == :gigantic # Les très gros vaisseaux ne peuvent pas être embarqués
    true
  end

  # Peut-il embarquer d'autres vaisseaux ?
  def can_embark_ships?
    capacity > 0
  end

  # Met à jour la capacité utilisée en fonction des vaisseaux embarqués
  def update_used_capacity!
    new_used_capacity = child_ships.sum(&:embarked_capacity)
    update_column(:used_capacity, new_used_capacity)
  end

  # Vérifie si un vaisseau peut être embarqué dans ce vaisseau
  def can_embark_ship?(ship)
    return false unless can_embark_ships?
    return false unless ship.can_be_embarked?
    used_capacity + ship.embarked_capacity <= capacity
  end

  # === MÉTHODES POUR LANCE-TORPILLES ET LANCE-MISSILES ===

  def torpedo_launcher
    ship_weapons.find_by(weapon_type: 'torpille')
  end

  def missile_launcher
    ship_weapons.find_by(weapon_type: 'missile')
  end

  def has_torpedo_launcher?
    torpilles? && torpedo_launcher.present?
  end

  def has_missile_launcher?
    missiles? && missile_launcher.present?
  end

  def can_install_torpedo_launcher?
    # Les vaisseaux scale 0 ou 1 ne peuvent pas installer de lance-torpilles
    scale_num = case scale.to_s
    when 'very_small' then 0
    when 'small' then 1
    when 'medium' then 2
    when 'big' then 3
    when 'very_big' then 4
    when 'gigantic' then 5
    else 0
    end
    scale_num >= 2
  end

  def can_buy_launcher?(launcher_type, user_credits)
    case launcher_type
    when 'torpille'
      return false unless can_install_torpedo_launcher?
      return false if has_torpedo_launcher?
      user_credits >= PREDEFINED_WEAPONS["Lance-Torpilles à protons"][:price]
    when 'missile'
      return false if has_missile_launcher?
      user_credits >= PREDEFINED_WEAPONS["Lance-Missiles à concussion"][:price]
    else
      false
    end
  end

  def buy_launcher!(launcher_type)
    weapon_config = case launcher_type
    when 'torpille'
      PREDEFINED_WEAPONS["Lance-Torpilles à protons"]
    when 'missile'
      PREDEFINED_WEAPONS["Lance-Missiles à concussion"]
    else
      return false
    end

    return false unless weapon_config
    return false unless can_install_torpedo_launcher? if launcher_type == 'torpille'

    ship_weapons.create!(
      name: launcher_type == 'torpille' ? 'Lance-Torpilles à protons' : 'Lance-Missiles à concussion',
      weapon_type: launcher_type,
      damage_mastery: weapon_config[:damage_mastery],
      damage_bonus: weapon_config[:damage_bonus],
      aim_mastery: weapon_config[:aim_mastery],
      aim_bonus: weapon_config[:aim_bonus],
      special: weapon_config[:special],
      quantity_max: 3,
      quantity_current: 3,
      price: weapon_config[:price]
    )

    case launcher_type
    when 'torpille'
      update!(torpilles: true)
    when 'missile'
      update!(missiles: true)
    end

    true
  end

  def can_buy_ammunition?(ammo_type, user_credits)
    launcher = case ammo_type
    when 'missile'
      missile_launcher
    when 'torpille'
      torpedo_launcher
    else
      nil
    end

    return false unless launcher.present?
    return false if launcher.quantity_current >= launcher.quantity_max
    user_credits >= AMMUNITION_CONFIG[ammo_type][:price]
  end

  def buy_ammunition!(ammo_type)
    launcher = case ammo_type
    when 'missile'
      missile_launcher
    when 'torpille'
      torpedo_launcher
    else
      return false
    end

    return false unless launcher.present?
    return false if launcher.quantity_current >= launcher.quantity_max

    launcher.update!(quantity_current: launcher.quantity_current + 1)
    true
  end

  def ammunition_price(ammo_type)
    AMMUNITION_CONFIG[ammo_type]&.dig(:price) || 0
  end

  # ===== GESTION DES TOURELLES =====
  
  # Retourne le nombre maximum de tourelles selon la scale du vaisseau
  def max_turrets
    scale_number = Ship.scales[scale]
    case scale_number
    when 0
      0 # Scale 0 ne peut pas avoir de tourelles
    when 1
      1 # Scale 1 peut avoir 1 tourelle
    when 2
      3 # Scale 2 peut avoir 3 tourelles
    else
      10 # Scale 3+ peut avoir jusqu'à 10 tourelles
    end
  end

  # Retourne les tourelles installées
  def installed_turrets
    ship_weapons.where(weapon_type: 'tourelle')
  end

  # Retourne les tourelles disponibles en stock
  def available_turrets
    turret_names = Ship::PREDEFINED_WEAPONS.select { |name, config| config[:weapon_type] == 'tourelle' }.keys
    ship_weapons.where(weapon_type: ['turret_stock', 'original'], name: turret_names)
  end

  # Retourne le nombre de tourelles installées
  def turret_count
    installed_turrets.count
  end

  # Vérifie si on peut installer une tourelle supplémentaire
  def can_install_turret?
    turret_count < max_turrets
  end

  # Vérifie si on peut acheter une tourelle
  def can_buy_turret?(turret_name, user_credits)
    return false unless PREDEFINED_WEAPONS.key?(turret_name)
    return false unless PREDEFINED_WEAPONS[turret_name][:weapon_type] == 'tourelle'
    return false unless can_install_turret?
    
    user_credits >= PREDEFINED_WEAPONS[turret_name][:price]
  end

  # Achète et installe automatiquement une tourelle
  def buy_turret!(turret_name)
    return false unless PREDEFINED_WEAPONS.key?(turret_name)
    return false unless PREDEFINED_WEAPONS[turret_name][:weapon_type] == 'tourelle'
    return false unless can_install_turret?

    turret_config = PREDEFINED_WEAPONS[turret_name]
    
    ship_weapons.create!(
      name: turret_name,
      weapon_type: 'tourelle',
      damage_mastery: turret_config[:damage_mastery],
      damage_bonus: turret_config[:damage_bonus],
      aim_mastery: turret_config[:aim_mastery],
      aim_bonus: turret_config[:aim_bonus],
      special: turret_config[:special],
      price: turret_config[:price]
    )
  end

  # Installe une tourelle depuis le stock
  def install_turret!(turret_id)
    turret = available_turrets.find_by(id: turret_id)
    return false unless turret
    return false unless can_install_turret?
    
    turret.update!(weapon_type: 'tourelle')
    true
  end

  # Désinstalle une tourelle (la remet en disponible)
  def uninstall_turret!(turret_id)
    turret = ship_weapons.find_by(id: turret_id, weapon_type: 'tourelle')
    return false unless turret
    
    # Remettre la tourelle en stock avec le type 'turret_stock' si elle a un prix, sinon 'original'
    turret.update!(weapon_type: turret.price > 0 ? 'turret_stock' : 'original')
    true
  end

  # Vend une tourelle (la supprime et retourne l'argent)
  def sell_turret!(turret_id)
    # Chercher dans les tourelles installées ET disponibles
    turret = ship_weapons.find_by(id: turret_id, weapon_type: ['tourelle', 'turret_stock', 'original'])
    return false unless turret
    return false if turret.price <= 0 # Ne peut pas vendre les tourelles originales (prix 0)
    
    sell_price = turret.price / 2 # Prix de vente = moitié du prix d'achat
    turret.destroy
    sell_price
  end

  # === ÉQUIPEMENTS SPÉCIAUX ===

  # Équipements spéciaux disponibles (achetés mais pas installés)
  def available_special_equipment
    ship_weapons.where(weapon_type: ['purchased', 'original']).select do |weapon|
      SPECIAL_EQUIPMENT.key?(weapon.name)
    end
  end

  # Équipements spéciaux installés
  def installed_special_equipment
    ship_weapons.where(weapon_type: 'special').select do |weapon|
      SPECIAL_EQUIPMENT.key?(weapon.name)
    end
  end

  # Vérifie si on peut acheter un équipement spécial
  def can_buy_special_equipment?(equipment_name, user_credits)
    equipment_config = SPECIAL_EQUIPMENT[equipment_name]
    return false unless equipment_config
    return false unless user_credits >= equipment_config[:price]
    
    # Pour les équipements à quantité limitée, vérifier qu'on n'a pas atteint la limite
    if equipment_config[:quantity_max] && equipment_config[:quantity_max] > 1
      current_total = total_equipment_quantity(equipment_name)
      return false if current_total >= equipment_config[:quantity_max]
    end
    
    true
  end

  # Achète un équipement spécial
  def buy_special_equipment!(equipment_name)
    equipment_config = SPECIAL_EQUIPMENT[equipment_name]
    return false unless equipment_config
    
    # Pour les équipements à quantité limitée
    if equipment_config[:quantity_max] && equipment_config[:quantity_max] > 1
      # Chercher s'il existe déjà un équipement de ce type
      existing_equipment = ship_weapons.where(name: equipment_name).first
      
      if existing_equipment
        # Incrémenter la quantité existante
        if existing_equipment.quantity_current < equipment_config[:quantity_max]
          existing_equipment.update!(quantity_current: existing_equipment.quantity_current + 1)
          return true
        else
          return false # Déjà au maximum
        end
      else
        # Créer un nouvel équipement avec 1 unité
        ship_weapons.create!(
          name: equipment_name,
          weapon_type: 'purchased',
          damage_mastery: 0,
          damage_bonus: 0,
          aim_mastery: 0,
          aim_bonus: 0,
          special: equipment_config[:special],
          price: equipment_config[:price],
          quantity_max: equipment_config[:quantity_max],
          quantity_current: 1
        )
        return true
      end
    else
      # Équipement normal (quantité unique)
      ship_weapons.create!(
        name: equipment_name,
        weapon_type: 'purchased',
        damage_mastery: 0,
        damage_bonus: 0,
        aim_mastery: 0,
        aim_bonus: 0,
        special: equipment_config[:special],
        price: equipment_config[:price],
        quantity_max: 1,
        quantity_current: 1
      )
      return true
    end
  end

  # Méthode helper pour calculer la quantité totale d'un équipement
  def total_equipment_quantity(equipment_name)
    ship_weapons.where(name: equipment_name).sum(:quantity_current)
  end

  # Installe un équipement spécial
  def install_special_equipment!(equipment_id)
    equipment = ship_weapons.find_by(id: equipment_id, weapon_type: ['purchased', 'original'])
    return false unless equipment
    return false unless SPECIAL_EQUIPMENT.key?(equipment.name)
    
    equipment.update!(weapon_type: 'special')
    true
  end

  # Désinstalle un équipement spécial (le remet en disponible)
  def uninstall_special_equipment!(equipment_id)
    equipment = ship_weapons.find_by(id: equipment_id, weapon_type: 'special')
    return false unless equipment
    return false unless SPECIAL_EQUIPMENT.key?(equipment.name)
    
    # Remettre l'équipement en stock avec le type 'purchased' si il a un prix, sinon 'original'
    equipment.update!(weapon_type: equipment.price > 0 ? 'purchased' : 'original')
    true
  end

  # Vend un équipement spécial (le supprime et retourne l'argent)
  def sell_special_equipment!(equipment_id)
    # Chercher dans les équipements installés ET disponibles
    equipment = ship_weapons.find_by(id: equipment_id, weapon_type: ['special', 'purchased', 'original'])
    return false unless equipment
    return false unless SPECIAL_EQUIPMENT.key?(equipment.name)
    return false if equipment.price <= 0 # Ne peut pas vendre les équipements originaux (prix 0)
    
    sell_price = equipment.price / 2 # Prix de vente = moitié du prix d'achat
    equipment.destroy
    sell_price
  end

  # Prix de vente d'un équipement spécial
  def special_equipment_sell_price(equipment_id)
    equipment = ship_weapons.find(equipment_id)
    return 0 if equipment.price <= 0
    equipment.price / 2
  end

  # === GESTION DES DROÏDES ASTROMECS ===

  # Vérifie si le vaisseau peut utiliser des droïdes astromecs (scale 3, 4 ou 5)
  def can_use_astromech_droids?
    scale_number = Ship.scales[scale]
    scale_number >= 3
  end

  # Vérifie si le vaisseau peut acheter plus de droïdes astromecs
  def can_buy_astromech_droid?
    can_use_astromech_droids? && astromech_droids < 5
  end

  # Vérifie si le vaisseau a des droïdes astromecs disponibles
  def has_astromech_droids?
    astromech_droids > 0
  end

  # Coût en kits de réparation selon la scale du vaisseau
  def repair_kit_cost
    scale_number = Ship.scales[scale]
    scale_number >= 3 ? 2 : 1
  end

  # === GESTION DE L'ÉQUIPAGE ===

  # Retourne les postes disponibles selon la scale du vaisseau
  def available_positions
    scale_number = Ship.scales[scale]  # Utilise l'enum Rails pour obtenir la valeur numérique
    base_positions = CrewMember::POSITIONS_BY_SCALE[scale_number] || []
    cannoneer_positions = []
    
    # Ajouter les postes de canonnier selon le nombre de tourelles installées
    installed_turrets.each_with_index do |turret, index|
      cannoneer_positions << "Canonnier #{index + 1}"
    end
    
    base_positions + cannoneer_positions
  end

  # Retourne les membres d'équipage assignés à un poste spécifique
  def crew_member_for_position(position)
    crew_members.find_by(position: position)
  end

  # Vérifie si un poste est occupé
  def position_occupied?(position)
    crew_member_for_position(position).present?
  end

  # Retourne tous les utilisateurs et pets disponibles pour l'équipage
  def available_crew_candidates
    group_users = group.users.includes(:avatar_attachment)
    # Récupérer tous les pets du quartier général
    headquarter = Headquarter.first
    group_pets = headquarter ? 
      Pet.joins(:building_pets)
         .joins("INNER JOIN buildings ON buildings.id = building_pets.building_id")
         .where("buildings.headquarter_id = ?", headquarter.id)
         .includes(:image_attachment) : 
      Pet.none
    
    {
      users: group_users,
      pets: group_pets
    }
  end

  private

  def set_initial_hp
    self.hp_current = hp_max if hp_max.present?
  end

  # Déduit l'échelle et la capacité à partir de la taille (size)
  def set_scale_and_capacity_from_size
    return if size.blank?
    meters = size.to_i
    case meters
    when 0..9
      self.scale = :very_small
      self.capacity = 0
    when 10..19
      self.scale = :small
      self.capacity = 0
    when 20..49
      self.scale = :medium
      self.capacity = 2
    when 50..99
      self.scale = :big
      self.capacity = 8
    when 100..299
      self.scale = :very_big
      self.capacity = 20
    else
      self.scale = :gigantic
      self.capacity = 50
    end
  end

  def used_capacity_cannot_exceed_capacity
    if used_capacity > capacity
      errors.add(:used_capacity, "ne peut pas dépasser la capacité maximale (#{capacity})")
    end
  end

  def update_parent_used_capacity
    if parent_ship_id_before_last_save.present?
      old_parent = Ship.find_by(id: parent_ship_id_before_last_save)
      old_parent&.update_used_capacity!
    end
    if parent_ship_id.present?
      parent_ship.update_used_capacity!
    end
  end

  def update_ship_skill_for_upgrade(type, old_level, new_level)
    # Récupérer le nom de la skill correspondante
    skill_name = SHIP_UPGRADES[type.to_sym][:skill_name]
    skill = Skill.find_by(name: skill_name)
    return unless skill

    # Trouver la ship_skill (elle existe forcément car créée à la création du vaisseau)
    ships_skill = ships_skills.find_by(skill: skill)
    return unless ships_skill

    # Retirer l'ancien bonus
    if old_level > 0
      old_bonus = SHIP_UPGRADES[type.to_sym][:levels][old_level][:bonus]
      remove_bonus_from_ship_skill(ships_skill, old_bonus)
    end

    # Appliquer le nouveau bonus
    new_bonus = SHIP_UPGRADES[type.to_sym][:levels][new_level][:bonus]
    apply_bonus_to_ship_skill(ships_skill, new_bonus)

    ships_skill.save!
  end

  def remove_bonus_from_ship_skill(ships_skill, bonus_string)
    case bonus_string
    when "+1"
      ships_skill.bonus = [ships_skill.bonus - 1, 0].max
    when "+2"
      ships_skill.bonus = [ships_skill.bonus - 2, 0].max
    when "+1D"
      ships_skill.mastery = [ships_skill.mastery - 1, 0].max
    end
  end

  def apply_bonus_to_ship_skill(ships_skill, bonus_string)
    case bonus_string
    when "+1"
      ships_skill.bonus += 1
    when "+2"
      ships_skill.bonus += 2
    when "+1D"
      ships_skill.mastery += 1
    end
  end
end
