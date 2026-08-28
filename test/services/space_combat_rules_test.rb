require "test_helper"
require "minitest/mock"

class SpaceCombatRulesTest < ActiveSupport::TestCase
  test "les armes principales et secondaires des vaisseaux joueurs sont des canons" do
    assert_equal :canon, SpaceCombatRules.normalize_weapon_type("main")
    assert_equal :canon, SpaceCombatRules.normalize_weapon_type("secondary")
    assert_equal :canon, SpaceCombatRules.normalize_weapon_type("canon")
    assert_equal :tourelle, SpaceCombatRules.normalize_weapon_type("tourelle")
  end

  test "un canon principal peut tirer en poursuite et en face à face" do
    assert SpaceCombatRules.can_fire?(:poursuivant, "main")
    assert SpaceCombatRules.can_fire?(:face_a_face, "secondary")
    refute SpaceCombatRules.can_fire?(:poursuivi, "main")
    refute SpaceCombatRules.can_fire?(:vol_parallele, "main")
    refute SpaceCombatRules.can_fire?(:hors_de_portee, "main")
  end

  test "tourelles et torpilles fonctionnent quand on est poursuivi ou en vol parallèle" do
    %i[poursuivi vol_parallele].each do |position|
      assert SpaceCombatRules.can_fire?(position, "tourelle"), "tourelle en #{position}"
      assert SpaceCombatRules.can_fire?(position, "torpille"), "torpille en #{position}"
      refute SpaceCombatRules.can_fire?(position, "missile"), "missile en #{position}"
    end
  end

  test "les missiles restent utilisables hors de portée" do
    assert SpaceCombatRules.can_fire?(:hors_de_portee, "missile")
    refute SpaceCombatRules.can_fire?(:hors_de_portee, "tourelle")
  end

  test "la poursuite donne +1D pour toucher et +1 au coup décisif" do
    assert_equal 1, SpaceCombatRules.aim_bonus_dice(:poursuivant)
    assert_equal 1, SpaceCombatRules.decisive_bonus(:poursuivant)
    assert_equal 0, SpaceCombatRules.aim_bonus_dice(:face_a_face)
    assert_equal 0, SpaceCombatRules.decisive_bonus(:vol_parallele)
  end

  test "le canonnier utilise sa compétence Tourelles" do
    assert_equal "Tourelles", SpaceCombatRules.skill_for_weapon("main", "Canonnier 1")
    assert_equal "Pilotage", SpaceCombatRules.skill_for_weapon("main", "Pilote")
    assert_equal "Tourelles", SpaceCombatRules.skill_for_weapon("tourelle", "Pilote")
  end

  test "l'égalité au jet opposé profite au défenseur" do
    SpaceCombatRules.stub(:roll_dice, ->(number, _sides = 6) { { individual: Array.new(number) { 3 }, total: number * 3 } }) do
      result = SpaceCombatRules.opposed_roll(2, 0, 2, 0)
      assert_equal :defender, result[:winner]
      assert_equal 0, result[:margin]
    end
  end

  test "la table des coups décisifs suit les règles" do
    assert_nil SpaceCombatRules.decisive_hit_for(12)[:flag]
    assert_equal "shields_disabled", SpaceCombatRules.decisive_hit_for(9)[:flag]
    assert_equal "weapon_damaged", SpaceCombatRules.decisive_hit_for(7)[:flag]
    assert_equal "thrusters_damaged", SpaceCombatRules.decisive_hit_for(5)[:flag]
    assert_nil SpaceCombatRules.decisive_hit_for(4)[:flag]
    assert_equal "hyperdrive_broken", SpaceCombatRules.decisive_hit_for(3)[:flag]
    assert_equal "depressurized", SpaceCombatRules.decisive_hit_for(2)[:flag]
    assert_equal "ship_destroyed", SpaceCombatRules.decisive_hit_for(1)[:flag]
  end

  test "un coup décisif se déclenche au-delà du tiers des PB max" do
    assert SpaceCombatRules.decisive_damage?(11, 30)
    refute SpaceCombatRules.decisive_damage?(10, 30)
    refute SpaceCombatRules.decisive_damage?(5, 0)
  end

  test "le commandement donne +1 par seuil de 5" do
    assert_equal 4, SpaceCombatRules.command_bonus_for(20)
    assert_equal 0, SpaceCombatRules.command_bonus_for(4)
  end

  test "l'astrogation prend un tour de plus en dessous de 15" do
    assert_equal 1, SpaceCombatRules.astrogation_turns_needed(15)
    assert_equal 2, SpaceCombatRules.astrogation_turns_needed(14)
    assert_equal 3, SpaceCombatRules.trace_difficulty(30)
    assert_equal 0, SpaceCombatRules.trace_difficulty(19)
  end
end
