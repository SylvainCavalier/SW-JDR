require "test_helper"

class ShipCombatPositionTest < ActiveSupport::TestCase
  setup do
    group = Group.find_or_create_by!(name: "PJ")
    ship = Ship.create!(name: "Vaisseau test", model: "M", group: group, hp_max: 20, hp_current: 20)
    enemy = EnemyShip.create!(name: "Ennemi test", hp_max: 10, speed_mastery: 2, piloting_mastery: 2,
                              hull_mastery: 1, shield_mastery: 0, scale: 0)
    @combat = SpaceCombatState.create!(turn: 1, active: false)
    @player = @combat.space_combat_participants.create!(participant: ship, side: 0)
    @enemy = @combat.space_combat_participants.create!(participant: enemy, side: 1)
    @position = ShipCombatPosition.find_or_create_pair(@combat.id, @player.id, @enemy.id)
  end

  test "la paire est toujours rangée dans l'ordre des identifiants" do
    assert @position.participant_a_id < @position.participant_b_id
    assert_equal @position, ShipCombatPosition.find_pair(@combat.id, @enemy.id, @player.id)
  end

  test "deux vaisseaux du même camp ne peuvent pas avoir de position relative" do
    other = @combat.space_combat_participants.create!(participant: @player.participant, side: 0)
    pair = ShipCombatPosition.new(space_combat_state: @combat, participant_a: @player, participant_b: other)
    refute pair.valid?
  end

  test "la position relative est symétrique" do
    @position.update!(position: @position.absolute_position_for(@player, :poursuivant))
    assert_equal :poursuivant, @position.relative_position_for(@player)
    assert_equal :poursuivi, @position.relative_position_for(@enemy)

    @position.update!(position: :face_to_face)
    assert_equal :face_a_face, @position.relative_position_for(@player)
    assert_equal :face_a_face, @position.relative_position_for(@enemy)
  end

  test "l'angle mort ne concerne que le vaisseau qui s'y est glissé" do
    @position.update!(blind_spot_for_id: @player.id)
    assert @position.blind_spot_for?(@player)
    refute @position.blind_spot_for?(@enemy)
    assert_equal @player, @position.blind_spot_participant
  end
end
