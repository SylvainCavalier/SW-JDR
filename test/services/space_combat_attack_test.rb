require "test_helper"
require "minitest/mock"

class SpaceCombatAttackTest < ActiveSupport::TestCase
  # Jets déterministes : chaque dé fait `value`
  def with_fixed_dice(value)
    stub = lambda do |number, _sides = 6|
      { individual: Array.new(number) { value }, total: number * value }
    end
    SpaceCombatRules.stub(:roll_dice, stub) { yield }
  end

  setup do
    @group = Group.find_or_create_by!(name: "PJ")
    @ship = Ship.create!(name: "Faucon test", model: "YT-1300", group: @group,
                         hp_max: 30, hp_current: 30, scale: :medium)
    { "Coque" => 2, "Ecrans" => 2, "Maniabilité" => 2, "Vitesse" => 4 }.each do |name, mastery|
      @ship.ships_skills.create!(skill: Skill.find_or_create_by!(name: name), mastery: mastery, bonus: 0)
    end
    @canon = @ship.ship_weapons.create!(name: "Canon blaster", weapon_type: "main",
                                        damage_mastery: 5, damage_bonus: 0, aim_mastery: 2, aim_bonus: 0)

    @enemy = EnemyShip.create!(name: "TIE test", hp_max: 20, speed_mastery: 3, speed_bonus: 0,
                               piloting_mastery: 2, piloting_bonus: 0, hull_mastery: 1, hull_bonus: 0,
                               shield_mastery: 0, shield_bonus: 0, scale: 0)

    @combat = SpaceCombatState.create!(turn: 1, active: false)
    @attacker = @combat.space_combat_participants.create!(participant: @ship, side: 0)
    @target = @combat.space_combat_participants.create!(participant: @enemy, side: 1)
    @position = ShipCombatPosition.find_or_create_pair(@combat.id, @attacker.id, @target.id)
    put_in_position(:poursuivant)
  end

  def put_in_position(relative)
    @position.update!(position: @position.absolute_position_for(@attacker, relative))
  end

  def fire(weapon = @canon, gunner: nil)
    SpaceCombatAttack.new(combat: @combat, attacker: @attacker, target: @target,
                          weapon: weapon, gunner: gunner).call
  end

  test "un canon principal peut tirer en poursuite" do
    result = with_fixed_dice(6) { fire }
    assert result.success?, result.error
    assert result.hit?
  end

  test "un canon principal ne peut pas tirer quand le vaisseau est poursuivi" do
    put_in_position(:poursuivi)
    result = fire
    refute result.success?
    assert_match(/Tir impossible/, result.error)
  end

  test "les dégâts sont réduits par la coque et les écrans" do
    # dégâts 5D à 6 = 30 ; coque 1D à 6 = 6 ; pas d'écrans -> 24 PB perdus
    with_fixed_dice(6) { fire }
    assert_equal 20 - 24, @enemy.reload.hp_current
    assert @enemy.ship_destroyed?
  end

  test "un tir raté ne fait aucun dégât" do
    # visée 2D (arme) + 1D (poursuite) contre une esquive de 6D : le tir échoue
    @enemy.update!(piloting_mastery: 6)
    result = with_fixed_dice(1) { fire }
    refute result.hit?
    assert_equal 20, @enemy.reload.hp_current
  end

  test "une perte de plus du tiers des PB déclenche un coup décisif" do
    result = with_fixed_dice(6) { fire }
    assert result.decisive, "un coup décisif aurait dû être tiré"
  end

  test "chaque tir subi ajoute un malus défensif cumulatif" do
    with_fixed_dice(3) { fire }
    assert_equal 1, @target.reload.defense_malus
  end

  test "les munitions sont décomptées et bloquent le tir à zéro" do
    torpedo = @ship.ship_weapons.create!(name: "Lance-Torpilles", weapon_type: "torpille",
                                          damage_mastery: 8, damage_bonus: 0, aim_mastery: 0, aim_bonus: 0,
                                          quantity_max: 1, quantity_current: 1)
    with_fixed_dice(6) { fire(torpedo) }
    assert_equal 0, torpedo.reload.quantity_current

    @attacker.update!(offensive_action_used: false)
    result = fire(torpedo)
    refute result.success?
    assert_match(/munitions/, result.error)
  end

  test "une cible furtive non détectée ne peut pas être visée" do
    @target.update!(stealth: true, detected: false)
    result = fire
    refute result.success?
    assert_match(/furtif/, result.error)
  end

  test "les commandes ionisées interdisent le tir" do
    @ship.update!(controls_ionized: true)
    result = fire
    refute result.success?
    assert_match(/ionisées/, result.error)
  end

  test "un gros vaisseau ne peut pas esquiver" do
    @enemy.update!(scale: 4)
    @ship.update!(scale: :big)
    result = with_fixed_dice(1) { fire }
    assert result.hit?, "un gros vaisseau ne manœuvre pas : le tir touche automatiquement"
  end

  test "un petit vaisseau doit atteindre 10 en pilotage pour toucher un gros vaisseau" do
    @enemy.update!(scale: 4)
    @ship.update!(scale: :very_small)
    result = with_fixed_dice(1) { fire } # pilotage 2D à 1 = 2 -> raté, et sous 15 les tourelles ripostent
    refute result.hit?
    assert result.entries.any? { |entry| entry[:message].include?("Tourelles automatiques") },
           "les tourelles automatiques doivent riposter en dessous de 15"
  end

  test "un petit vaisseau qui dépasse 15 en pilotage évite les tourelles automatiques" do
    @enemy.update!(scale: 4)
    @ship.update!(scale: :very_small)
    result = with_fixed_dice(6) { fire } # pilotage 2D à 6 = 12 -> touche mais reste sous 15
    assert result.hit?
    assert result.entries.any? { |entry| entry[:message].include?("Tourelles automatiques") }
  end

  test "les missiles ne peuvent pas rater un gros vaisseau" do
    @enemy.update!(scale: 4)
    missile = @ship.ship_weapons.create!(name: "Lance-Missiles", weapon_type: "missile",
                                          damage_mastery: 6, damage_bonus: 0, aim_mastery: 0, aim_bonus: 0)
    result = with_fixed_dice(1) { fire(missile) }
    assert result.hit?
  end

  test "les écrans désactivés n'absorbent plus rien" do
    @enemy.update!(shield_mastery: 3, hp_max: 100, hp_current: 100)
    with_fixed_dice(6) { fire }
    with_shields = 100 - @enemy.reload.hp_current

    @enemy.update!(hp_current: 100, shields_disabled: true)
    @attacker.update!(offensive_action_used: false)
    @target.update!(defense_malus: 0)
    with_fixed_dice(6) { fire }
    without_shields = 100 - @enemy.reload.hp_current

    assert without_shields > with_shields
  end
end
