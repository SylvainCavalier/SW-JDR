# Règles chiffrées du combat spatial (chapitre 4 des règles).
# Uniquement des fonctions pures : aucun accès base de données ici.
class SpaceCombatRules
  # Types d'armes tels que stockés en base (ship_weapons / enemy_ship_weapons)
  KNOWN_WEAPON_TYPES = %w[main secondary canon tourelle missile torpille special].freeze

  # Les armes principales et secondaires des vaisseaux joueurs sont des canons.
  WEAPON_TYPE_ALIASES = {
    "main" => :canon,
    "secondary" => :canon,
    "canon" => :canon,
    "tourelle" => :tourelle,
    "missile" => :missile,
    "torpille" => :torpille,
    "special" => :special
  }.freeze

  # Armes utilisables selon la position relative (règle 4-3)
  WEAPON_MATRIX = {
    poursuivant: { canon: true, tourelle: true, missile: true, torpille: true, special: true },
    poursuivi: { canon: false, tourelle: true, missile: false, torpille: true, special: true },
    face_a_face: { canon: true, tourelle: true, missile: true, torpille: true, special: true },
    vol_parallele: { canon: false, tourelle: true, missile: false, torpille: true, special: true },
    # Hors de portée : seuls les missiles peuvent encore atteindre une cible en ligne de mire
    hors_de_portee: { canon: false, tourelle: false, missile: true, torpille: false, special: false }
  }.freeze

  # Compétence de PJ utilisée pour le jet de tir, selon le type d'arme
  WEAPON_SKILL = {
    canon: "Pilotage",
    tourelle: "Tourelles",
    missile: "Pilotage",
    torpille: "Pilotage",
    special: "Pilotage"
  }.freeze

  # Coup décisif : jet de chance D12 (règle 4-6)
  DECISIVE_HIT_TABLE = [
    { range: (11..99), flag: nil,                 label: "Aucune conséquence supplémentaire" },
    { range: (9..10),  flag: "shields_disabled",  label: "Écrans désactivés" },
    { range: (7..8),   flag: "weapon_damaged",    label: "Canon touché" },
    { range: (5..6),   flag: "thrusters_damaged", label: "Propulseur touché" },
    { range: (4..4),   flag: nil,                 label: "Soute touchée : 5 objets perdus au hasard" },
    { range: (3..3),   flag: "hyperdrive_broken", label: "Hyperdrive touché" },
    { range: (2..2),   flag: "depressurized",     label: "Vaisseau dépressurisé" },
    { range: (-99..1), flag: "ship_destroyed",    label: "Vaisseau détruit" }
  ].freeze

  # Petit vaisseau attaquant un gros vaisseau (règle 4-9)
  SMALL_VS_BIG_HIT_THRESHOLD = 10
  SMALL_VS_BIG_SAFE_THRESHOLD = 15
  AUTO_TURRET_DAMAGE_DICE = 4

  # Un seuil de commandement (+1 à tous les postes) tous les 5 points
  COMMAND_THRESHOLD_STEP = 5

  # Astrogation : sous ce seuil, le calcul prend un tour de plus (règle 4-8)
  ASTROGATION_FAST_THRESHOLD = 15
  ASTROGATION_TRACE_THRESHOLDS = [20, 25, 30].freeze

  # Réparation d'urgence : jet de réparation / 2 (règle 4-4)
  REPAIR_DIVISOR = 2

  # Un coup décisif se déclenche aussi au-delà de ce ratio de PB perdus d'un coup
  DECISIVE_DAMAGE_RATIO = 1.0 / 3

  class << self
    def normalize_weapon_type(weapon_type)
      WEAPON_TYPE_ALIASES[weapon_type.to_s] || :special
    end

    def can_fire?(relative_position, weapon_type)
      matrix = WEAPON_MATRIX[relative_position.to_sym]
      return false unless matrix

      matrix[normalize_weapon_type(weapon_type)] || false
    end

    def skill_for_weapon(weapon_type, crew_position = nil)
      return "Tourelles" if crew_position.to_s.start_with?("Canonnier")

      WEAPON_SKILL[normalize_weapon_type(weapon_type)] || "Pilotage"
    end

    # +1D pour toucher quand on poursuit l'ennemi (règle 4-3)
    def aim_bonus_dice(relative_position)
      relative_position.to_sym == :poursuivant ? 1 : 0
    end

    # +1 au jet de chance du coup décisif quand on poursuit
    def decisive_bonus(relative_position)
      relative_position.to_sym == :poursuivant ? 1 : 0
    end

    def roll_dice(number_of_dice, sides = 6)
      count = [number_of_dice.to_i, 0].max
      rolls = Array.new(count) { rand(1..sides) }
      { individual: rolls, total: rolls.sum }
    end

    # Jet complet : [mastery, bonus] -> détail du jet
    def roll(mastery, bonus = 0)
      result = roll_dice(mastery)
      {
        mastery: mastery.to_i,
        bonus: bonus.to_i,
        rolls: result[:individual],
        total: result[:total] + bonus.to_i
      }
    end

    def format_roll(roll_hash)
      dice = roll_hash[:rolls].join(", ")
      bonus = roll_hash[:bonus].to_i
      bonus.zero? ? "[#{dice}] = #{roll_hash[:total]}" : "[#{dice}]#{format('%+d', bonus)} = #{roll_hash[:total]}"
    end

    # Jet opposé : l'attaquant doit faire STRICTEMENT mieux que le défenseur.
    def opposed_roll(atk_mastery, atk_bonus, def_mastery, def_bonus)
      attacker = roll(atk_mastery, atk_bonus)
      defender = roll(def_mastery, def_bonus)

      {
        attacker: attacker.merge(rolls: attacker[:rolls], bonus: attacker[:bonus], total: attacker[:total]),
        defender: defender,
        winner: attacker[:total] > defender[:total] ? :attacker : :defender,
        margin: (attacker[:total] - defender[:total]).abs
      }
    end

    def luck_roll
      rand(1..12)
    end

    def decisive_hit_for(luck)
      DECISIVE_HIT_TABLE.find { |entry| entry[:range].cover?(luck) }
    end

    def decisive_damage?(hp_lost, hp_max)
      return false if hp_max.to_i <= 0

      hp_lost.to_f > hp_max.to_f * DECISIVE_DAMAGE_RATIO
    end

    def command_bonus_for(roll_total)
      [roll_total.to_i / COMMAND_THRESHOLD_STEP, 0].max
    end

    def astrogation_turns_needed(roll_total)
      roll_total.to_i >= ASTROGATION_FAST_THRESHOLD ? 1 : 2
    end

    def trace_difficulty(roll_total)
      ASTROGATION_TRACE_THRESHOLDS.count { |threshold| roll_total.to_i >= threshold }
    end
  end
end
