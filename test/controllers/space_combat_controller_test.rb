require "test_helper"

class SpaceCombatControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @pj_group = Group.find_or_create_by!(name: "PJ")
    @mj_group = Group.find_or_create_by!(name: "MJ")
    @player = create_user("pilote", @pj_group)
    @mj = create_user("maitre", @mj_group)

    @ship = Ship.create!(name: "Faucon test", model: "YT", group: @pj_group,
                         hp_max: 30, hp_current: 30, scale: :medium)
    { "Coque" => 2, "Ecrans" => 2, "Maniabilité" => 2, "Vitesse" => 4 }.each do |name, mastery|
      @ship.ships_skills.create!(skill: Skill.find_or_create_by!(name: name), mastery: mastery, bonus: 0)
    end
    @weapon = @ship.ship_weapons.create!(name: "Canon blaster", weapon_type: "main",
                                        damage_mastery: 9, damage_bonus: 0, aim_mastery: 9, aim_bonus: 0)

    @enemy_ship = EnemyShip.create!(name: "TIE test", hp_max: 20, speed_mastery: 2, speed_bonus: 0,
                                    piloting_mastery: 1, piloting_bonus: 0, hull_mastery: 1, hull_bonus: 0,
                                    shield_mastery: 0, shield_bonus: 0, scale: 0)

    @combat = SpaceCombatState.create!(turn: 1, active: true)
    @player_participant = @combat.space_combat_participants.create!(participant: @ship, side: 0)
    @enemy_participant = @combat.space_combat_participants.create!(participant: @enemy_ship, side: 1)
    @position = ShipCombatPosition.find_or_create_pair(@combat.id, @player_participant.id, @enemy_participant.id)
    @position.update!(position: @position.absolute_position_for(@player_participant, :poursuivant))
  end

  def create_user(username, group)
    User.create!(username: username, email: "#{username}@example.com",
                 password: "password", password_confirmation: "password", group: group,
                 hp_current: 10, hp_max: 10)
  end

  test "la page est accessible aux joueurs et au MJ" do
    sign_in @player
    get space_combat_path
    assert_response :success

    sign_in @mj
    get mj_space_combat_path
    assert_response :success
  end

  test "seul le MJ peut lancer l'initiative" do
    sign_in @player
    post space_combat_roll_initiative_path, as: :json
    assert_response :forbidden

    sign_in @mj
    post space_combat_roll_initiative_path, as: :json
    assert_response :success
    assert_equal [1, 2], @combat.space_combat_participants.pluck(:action_order).compact.sort
  end

  test "un tir applique les dégâts et journalise le jet" do
    sign_in @player
    assert_changes -> { @combat.space_combat_actions.where(action_type: "tir").count } do
      post space_combat_fire_weapon_path,
           params: { attacker_id: @player_participant.id, target_id: @enemy_participant.id,
                     weapon_id: @weapon.id }, as: :json
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert body["success"]
    assert body["hit"], "avec 9D de visée contre 1D de pilotage, le tir doit toucher"
    assert @enemy_ship.reload.hp_current < 20
    assert @player_participant.reload.offensive_action_used
    assert @position.reload.engaged?
  end

  test "un canon ne peut pas tirer quand le vaisseau est poursuivi" do
    @position.update!(position: @position.absolute_position_for(@player_participant, :poursuivi))
    sign_in @player

    post space_combat_fire_weapon_path,
         params: { attacker_id: @player_participant.id, target_id: @enemy_participant.id,
                   weapon_id: @weapon.id }, as: :json

    assert_response :unprocessable_entity
    assert_equal 20, @enemy_ship.reload.hp_current
  end

  test "un joueur ne peut pas agir sur un vaisseau ennemi" do
    sign_in @player
    patch space_combat_countermeasure_path, params: { participant_id: @enemy_participant.id }, as: :json
    assert_response :forbidden
  end

  test "le tour avance automatiquement quand tous les vaisseaux ont joué" do
    @player_participant.update!(action_order: 1)
    @enemy_participant.update!(action_order: 2, has_played: true)

    sign_in @player
    patch space_combat_end_turn_path, params: { participant_id: @player_participant.id }, as: :json

    assert_response :success
    assert JSON.parse(response.body)["turn_advanced"]
    assert_equal 2, @combat.reload.turn
    refute @player_participant.reload.has_played
  end

  test "le passage au tour suivant recharge les écrans et applique les réparations" do
    @ship.update!(shields_disabled: true, hp_current: 10)
    @player_participant.update!(shields_down_until_turn: 2, pending_repair: 5, defense_malus: 3)

    sign_in @mj
    patch space_combat_next_turn_path, as: :json

    assert_response :success
    refute @ship.reload.shields_disabled?, "les écrans se rechargent en un tour complet"
    assert_equal 15, @ship.hp_current
    assert_equal 0, @player_participant.reload.pending_repair
    assert_equal 0, @player_participant.defense_malus
  end

  test "activer le statut écrans désactivés programme leur rechargement" do
    sign_in @mj
    patch space_combat_update_damage_flag_path,
          params: { participant_id: @player_participant.id, flag: "shields_disabled" }, as: :json

    assert_response :success
    assert @ship.reload.shields_disabled?
    assert_equal @combat.turn + 1, @player_participant.reload.shields_down_until_turn
  end

  test "un joueur hors équipage ne peut pas manœuvrer un vaisseau qui a un équipage" do
    autre = create_user("copilote", @pj_group)
    @ship.crew_members.create!(assignable: autre, position: "Pilote")

    sign_in @player
    patch space_combat_countermeasure_path, params: { participant_id: @player_participant.id }, as: :json
    assert_response :forbidden

    sign_in autre
    patch space_combat_countermeasure_path, params: { participant_id: @player_participant.id }, as: :json
    assert_response :success
  end

  test "la réparation d'urgence consomme un kit et se déclenche au tour suivant" do
    kit = InventoryObject.find_or_create_by!(name: "Kit de réparation")
    stock = @player.user_inventory_objects.create!(inventory_object: kit, quantity: 2)
    @player.user_skills.create!(skill: Skill.find_or_create_by!(name: "Réparation"), mastery: 4, bonus: 0)
    @ship.update!(hp_current: 10)

    sign_in @player
    patch space_combat_repair_path, params: { participant_id: @player_participant.id, mode: "kit" }, as: :json

    assert_response :success
    assert_equal 1, stock.reload.quantity
    assert @player_participant.reload.repair_used
    assert @player_participant.pending_repair.positive?
    assert_equal 10, @ship.reload.hp_current, "les PB ne reviennent qu'au tour suivant"

    sign_in @mj
    patch space_combat_next_turn_path, as: :json
    assert @ship.reload.hp_current > 10
  end

  test "le jet de commandement donne un bonus à tous les postes du vaisseau" do
    @player.user_skills.create!(skill: Skill.find_or_create_by!(name: "Commandement"), mastery: 10, bonus: 0)

    sign_in @player
    patch space_combat_command_path, params: { participant_id: @player_participant.id }, as: :json

    assert_response :success
    assert @player_participant.reload.command_used
    assert @player_participant.captain_bonus.positive?
  end

  test "la manœuvre de fuite exige d'être hors de portée" do
    sign_in @player
    patch space_combat_flee_path, params: { participant_id: @player_participant.id }, as: :json
    assert_response :unprocessable_entity

    @position.update!(position: :out_of_range)
    patch space_combat_flee_path, params: { participant_id: @player_participant.id }, as: :json
    assert_response :success
  end
end
