# Résolution complète d'un tir en combat spatial (règles 4-3, 4-6, 4-9).
#
#   result = SpaceCombatAttack.new(combat:, attacker:, target:, weapon:, gunner:).call
#   result.success? / result.hit? / result.entries -> lignes à journaliser
class SpaceCombatAttack
  Result = Struct.new(:success, :error, :entries, :hit, :hp_lost, :decisive, :summary, keyword_init: true) do
    def success? = success
    def hit? = hit
  end

  attr_reader :combat, :attacker, :target, :weapon, :gunner

  def initialize(combat:, attacker:, target:, weapon:, gunner: nil)
    @combat = combat
    @attacker = attacker
    @target = target
    @weapon = weapon
    @gunner = gunner
    @entries = []
  end

  def call
    error = validation_error
    return Result.new(success: false, error: error, entries: []) if error

    consume_ammo!
    duel_lost_by_defender = face_to_face_duel!

    hit = resolve_hit
    hp_lost = 0
    decisive = nil

    if hit
      hp_lost = apply_damage!
      apply_weapon_side_effects!
      interrupt_hyperspace!
      if duel_lost_by_defender || SpaceCombatRules.decisive_damage?(hp_lost, target.hp_max)
        decisive = apply_decisive_hit!
      end
      check_destruction!
    end

    Result.new(
      success: true, error: nil, entries: @entries,
      hit: hit, hp_lost: hp_lost, decisive: decisive, summary: @entries.map { |e| e[:message] }.join(" · ")
    )
  end

  private

  def position
    @position ||= ShipCombatPosition.find_pair(combat.id, attacker.id, target.id)
  end

  def relative_position
    @relative_position ||= position&.relative_position_for(attacker)
  end

  def weapon_type
    @weapon_type ||= SpaceCombatRules.normalize_weapon_type(weapon.weapon_type)
  end

  def weapon_label
    @weapon_label ||= SpaceCombatStats.weapon_label(weapon)
  end

  def weapon_special
    weapon.respond_to?(:special) ? weapon.special.to_s : ""
  end

  # --- Vérifications --------------------------------------------------------

  def validation_error
    return "Pas de position définie entre ces vaisseaux" unless position
    return "#{attacker.ship_name} est hors combat" if attacker.out_of_combat?
    return "#{target.ship_name} est déjà hors combat" if target.out_of_combat?
    return "Commandes ionisées : seules les actions de mouvement sont possibles" if attacker.ionized?
    return "Action offensive déjà utilisée ce tour" if attacker.offensive_action_used?
    return "#{target.ship_name} est furtif et n'a pas encore été détecté" if target.stealth? && !target.detected?

    if attacker.ship.weapon_damaged? && weapon_type == :canon && SpaceCombatStats.canon_count(attacker.ship) <= 1
      return "Canon touché : plus aucun canon opérationnel"
    end

    unless SpaceCombatRules.can_fire?(relative_position, weapon.weapon_type)
      return "Tir impossible en position « #{ShipCombatPosition::RELATIVE_LABELS[relative_position]} » avec cette arme"
    end

    if position.blind_spot_for?(target) && !%i[missile torpille].include?(weapon_type)
      return "#{target.ship_name} est dans l'angle mort : seuls missiles et torpilles peuvent l'atteindre"
    end

    ammo = SpaceCombatStats.ammo_left(weapon)
    return "Plus de munitions pour #{weapon_label}" if ammo && ammo <= 0

    nil
  end

  # --- Étapes ---------------------------------------------------------------

  def consume_ammo!
    return if SpaceCombatStats.unlimited_ammo?(weapon)

    weapon.update!(quantity_current: [weapon.quantity_current.to_i - 1, 0].max)
    log("tir", "Munitions #{weapon_label} : #{weapon.quantity_current}/#{weapon.quantity_max}")
  end

  # Face à face : jet de pilotage opposé pour savoir qui tire en premier (règle 4-3).
  # Le perdant du duel encaisse un coup décisif s'il est touché (règle 4-6).
  def face_to_face_duel!
    return false unless relative_position == :face_a_face && weapon_type == :canon

    atk_m, atk_b = attacker.piloting_dice(gunner)
    def_m, def_b = target.piloting_dice
    duel = SpaceCombatRules.opposed_roll(atk_m, atk_b, def_m, def_b)

    detail = "(#{SpaceCombatRules.format_roll(duel[:attacker])} vs #{SpaceCombatRules.format_roll(duel[:defender])})"

    if duel[:winner] == :attacker
      log("tir", "Face à face : #{attacker.ship_name} tire en premier #{detail}")
      true
    else
      log("tir", "Face à face : #{target.ship_name} tire en premier, " \
                 "le MJ résout le tir adverse #{detail}")
      false
    end
  end

  def attack_dice
    aim = [weapon.aim_mastery.to_i, weapon.aim_bonus.to_i]
    crew = if attacker.player_ship?
             skill = SpaceCombatRules.skill_for_weapon(weapon.weapon_type, attacker.crew_position_for(gunner))
             SpaceCombatStats.user_dice(gunner, skill)
           else
             SpaceCombatStats.ship_dice(attacker.ship, :piloting)
           end

    mastery, bonus = SpaceCombatStats.add(aim, crew)
    [mastery + SpaceCombatRules.aim_bonus_dice(relative_position), bonus + attacker.captain_bonus]
  end

  def resolve_hit
    guided = %i[missile torpille].include?(weapon_type)
    return resolve_small_vs_big if attacker.small_ship? && target.big_ship? && !guided
    return resolve_against_big_ship if target.big_ship?

    resolve_opposed
  end

  # Jet de visée opposé à l'esquive spatiale de la cible
  def resolve_opposed
    atk_m, atk_b = attack_dice
    attack = SpaceCombatRules.roll(atk_m, atk_b)

    def_m, def_b = target.evasion_dice
    defense = SpaceCombatRules.roll(def_m, def_b)
    target.update!(defense_malus: target.defense_malus + 1)

    hit = attack[:total] > defense[:total]
    bonus_note = SpaceCombatRules.aim_bonus_dice(relative_position).positive? ? " (+1D poursuivant)" : ""

    log("tir",
        "#{attacker.ship_name} tire (#{weapon_label}) sur #{target.ship_name}#{bonus_note} : " \
        "visée #{SpaceCombatRules.format_roll(attack)} vs esquive #{SpaceCombatRules.format_roll(defense)} " \
        "-> #{hit ? 'TOUCHÉ' : 'raté'}")
    hit
  end

  # Petit vaisseau contre gros vaisseau : seuils fixes + tourelles automatiques (règle 4-9)
  def resolve_small_vs_big
    mastery, bonus = attacker.piloting_dice(gunner)
    roll = SpaceCombatRules.roll(mastery, bonus)
    hit = roll[:total] >= SpaceCombatRules::SMALL_VS_BIG_HIT_THRESHOLD

    log("tir",
        "#{attacker.ship_name} attaque le gros vaisseau #{target.ship_name} : " \
        "pilotage #{SpaceCombatRules.format_roll(roll)} " \
        "(#{SpaceCombatRules::SMALL_VS_BIG_HIT_THRESHOLD} pour toucher, " \
        "#{SpaceCombatRules::SMALL_VS_BIG_SAFE_THRESHOLD} pour éviter les tourelles) -> #{hit ? 'TOUCHÉ' : 'raté'}")

    auto_turret_fire! if roll[:total] < SpaceCombatRules::SMALL_VS_BIG_SAFE_THRESHOLD
    hit
  end

  # Missiles / torpilles contre un gros vaisseau : ne peuvent pas rater,
  # sauf interception automatique. Gros vaisseau contre gros vaisseau : pas d'esquive.
  def resolve_against_big_ship
    if %i[missile torpille].include?(weapon_type)
      level = target.ship.respond_to?(:interception_level) ? target.ship.interception_level.to_i : 0
      if level.positive?
        luck = SpaceCombatRules.luck_roll
        if luck < level
          log("tir", "#{weapon_label} interceptée par les défenses de #{target.ship_name} " \
                     "(jet de chance #{luck} < #{level})")
          return false
        end
        log("tir", "#{weapon_label} passe les interceptions de #{target.ship_name} (jet de chance #{luck})")
      end
      log("tir", "#{weapon_label} de #{attacker.ship_name} touche automatiquement #{target.ship_name}")
      return true
    end

    log("tir", "#{attacker.ship_name} (#{weapon_label}) touche #{target.ship_name} : " \
               "un gros vaisseau ne peut pas manœuvrer pour esquiver")
    true
  end

  def auto_turret_fire!
    damage = SpaceCombatRules.roll(SpaceCombatRules::AUTO_TURRET_DAMAGE_DICE, 0)
    absorbed, detail = absorption_for(attacker)
    lost = [damage[:total] - absorbed, 0].max
    apply_hp_loss!(attacker, lost)

    log("degats",
        "Tourelles automatiques de #{target.ship_name} sur #{attacker.ship_name} : " \
        "#{SpaceCombatRules.format_roll(damage)} - #{detail} = #{lost} PB perdus", attacker)
  end

  # --- Dégâts ---------------------------------------------------------------

  def absorption_for(participant)
    hull_m, hull_b = participant.hull_dice
    hull = SpaceCombatRules.roll(hull_m, hull_b)
    parts = ["coque #{SpaceCombatRules.format_roll(hull)}"]
    total = hull[:total]

    if participant.shields_active? && !weapon_special.downcase.include?("traversant")
      shield_m, shield_b = participant.shield_dice
      shield = SpaceCombatRules.roll(shield_m, shield_b)
      parts << "écrans #{SpaceCombatRules.format_roll(shield)}"
      total += shield[:total]
    elsif participant.shields_active?
      parts << "écrans traversés"
    end

    [total, parts.join(" + ")]
  end

  def apply_damage!
    damage = SpaceCombatRules.roll(weapon.damage_mastery, weapon.damage_bonus)
    absorbed, detail = absorption_for(target)
    lost = [damage[:total] - absorbed, 0].max
    apply_hp_loss!(target, lost)

    log("degats",
        "Dégâts #{weapon_label} : #{SpaceCombatRules.format_roll(damage)} - (#{detail}) = " \
        "#{lost} PB -> #{target.ship_name} #{target.ship.hp_current}/#{target.ship.hp_max}", target)
    lost
  end

  def apply_hp_loss!(participant, lost)
    return if lost.zero?

    participant.ship.update!(hp_current: participant.ship.hp_current.to_i - lost)
  end

  def apply_weapon_side_effects!
    return unless weapon_special.downcase.include?("ion")
    return if target.ship.controls_ionized?

    target.ship.update!(controls_ionized: true)
    log("flag_damage", "#{target.ship_name} : commandes ionisées par #{weapon_label}", target)
  end

  def interrupt_hyperspace!
    return unless target.astrogation_started?

    target.update!(astrogation_started: false, astrogation_turns: 0, hyperspace_ready: false)
    log("hyperespace", "Le calcul d'astrogation de #{target.ship_name} est interrompu par le tir", target)
  end

  def apply_decisive_hit!
    luck = SpaceCombatRules.luck_roll + SpaceCombatRules.decisive_bonus(relative_position)
    entry = SpaceCombatRules.decisive_hit_for(luck)

    log("coup_decisif", "COUP DÉCISIF sur #{target.ship_name} — jet de chance #{luck} : #{entry[:label]}", target)
    apply_flag!(entry[:flag]) if entry[:flag]
    entry
  end

  def apply_flag!(flag)
    ship = target.ship
    ship.update!(flag => true)

    case flag
    when "shields_disabled"
      target.update!(shields_down_until_turn: combat.turn + 1)
    when "thrusters_damaged"
      target.update!(thruster_hits: target.thruster_hits + 1)
      log("flag_damage", "#{target.ship_name} : #{target.thruster_hits}/#{SpaceCombatParticipant::MAX_THRUSTER_HITS} " \
                         "propulseurs touchés#{target.adrift? ? ' — le vaisseau part à la dérive' : ''}", target)
    when "depressurized"
      target.update!(depressurized_since_turn: combat.turn)
    end
  end

  def check_destruction!
    return unless target.ship.hp_current.to_i <= 0 && !target.ship.ship_destroyed?

    target.ship.update!(ship_destroyed: true)
    log("coup_decisif", "#{target.ship_name} passe sous 0 PB : le vaisseau est détruit", target)
  end

  # --- Journal --------------------------------------------------------------

  def log(type, message, target_participant = nil)
    @entries << { type: type, message: message, target: target_participant }
  end
end
