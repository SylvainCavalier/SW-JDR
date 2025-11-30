# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_11_30_140000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "apprentice_caracs", force: :cascade do |t|
    t.bigint "apprentice_id", null: false
    t.bigint "carac_id", null: false
    t.integer "mastery", default: 0, null: false
    t.integer "bonus", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["apprentice_id", "carac_id"], name: "index_apprentice_caracs_on_apprentice_id_and_carac_id", unique: true
    t.index ["apprentice_id"], name: "index_apprentice_caracs_on_apprentice_id"
    t.index ["carac_id"], name: "index_apprentice_caracs_on_carac_id"
  end

  create_table "apprentice_skills", force: :cascade do |t|
    t.bigint "apprentice_id", null: false
    t.bigint "skill_id", null: false
    t.integer "mastery", default: 0, null: false
    t.integer "bonus", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "talent"
    t.index ["apprentice_id", "skill_id"], name: "index_apprentice_skills_on_apprentice_id_and_skill_id", unique: true
    t.index ["apprentice_id"], name: "index_apprentice_skills_on_apprentice_id"
    t.index ["skill_id"], name: "index_apprentice_skills_on_skill_id"
  end

  create_table "apprentices", force: :cascade do |t|
    t.string "jedi_name"
    t.bigint "pet_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "side", default: 0
    t.string "speciality", default: "Commun"
    t.integer "midi_chlorians"
    t.string "saber_style"
    t.bigint "user_id", null: false
    t.integer "dark_side_points", default: 0
    t.integer "fatigue", default: 100, null: false
    t.boolean "midi_chlorians_revealed", default: false, null: false
    t.index ["pet_id"], name: "index_apprentices_on_pet_id"
    t.index ["user_id"], name: "index_apprentices_on_user_id"
  end

  create_table "building_pets", force: :cascade do |t|
    t.bigint "building_id", null: false
    t.bigint "pet_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["building_id"], name: "index_building_pets_on_building_id"
    t.index ["pet_id"], name: "index_building_pets_on_pet_id"
  end

  create_table "buildings", force: :cascade do |t|
    t.string "name"
    t.integer "level", default: 0
    t.string "description"
    t.integer "price"
    t.string "category"
    t.bigint "chief_pet_id"
    t.bigint "headquarter_id", null: false
    t.jsonb "properties", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chief_pet_id"], name: "index_buildings_on_chief_pet_id"
    t.index ["headquarter_id"], name: "index_buildings_on_headquarter_id"
  end

  create_table "caracs", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chatouille_states", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "faith_points", default: 10, null: false
    t.integer "missionaries", default: 1, null: false
    t.integer "religion_credits", default: 5000, null: false
    t.decimal "market_share", precision: 5, scale: 2, default: "1.0", null: false
    t.integer "political_influence", default: 0, null: false
    t.integer "current_step", default: 1, null: false
    t.integer "temples_count", default: 0, null: false
    t.integer "flying_temple", default: 0, null: false
    t.boolean "council_observer", default: false, null: false
    t.boolean "council_member", default: false, null: false
    t.integer "current_event_index"
    t.boolean "event_available", default: false, null: false
    t.jsonb "completed_events", default: []
    t.jsonb "planets_reached", default: []
    t.integer "total_converts", default: 0, null: false
    t.integer "scandals_survived", default: 0, null: false
    t.integer "miracles_performed", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_chatouille_states_on_user_id"
  end

  create_table "classe_persos", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "combat_actions", force: :cascade do |t|
    t.string "actor_type", null: false
    t.bigint "actor_id", null: false
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.string "action_type"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_type", "actor_id"], name: "index_combat_actions_on_actor"
    t.index ["target_type", "target_id"], name: "index_combat_actions_on_target"
  end

  create_table "combat_states", force: :cascade do |t|
    t.integer "turn"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "crew_members", force: :cascade do |t|
    t.bigint "ship_id", null: false
    t.string "assignable_type"
    t.integer "assignable_id"
    t.string "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ship_id"], name: "index_crew_members_on_ship_id"
  end

  create_table "defenses", force: :cascade do |t|
    t.string "name", null: false
    t.integer "price", null: false
    t.text "description", null: false
    t.integer "bonus", default: 0
    t.bigint "headquarter_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["headquarter_id"], name: "index_defenses_on_headquarter_id"
  end

  create_table "embryo_skills", force: :cascade do |t|
    t.bigint "embryo_id", null: false
    t.bigint "skill_id", null: false
    t.integer "mastery", default: 0, null: false
    t.integer "bonus", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["embryo_id", "skill_id"], name: "index_embryo_skills_on_embryo_id_and_skill_id", unique: true
    t.index ["embryo_id"], name: "index_embryo_skills_on_embryo_id"
    t.index ["skill_id"], name: "index_embryo_skills_on_skill_id"
  end

  create_table "embryos", force: :cascade do |t|
    t.string "name", null: false
    t.string "creature_type", null: false
    t.string "race"
    t.string "gender"
    t.string "status", default: "stocké"
    t.string "weapon"
    t.integer "damage_1", default: 0
    t.integer "damage_bonus_1", default: 0
    t.jsonb "special_traits", default: []
    t.boolean "force", default: false
    t.integer "size"
    t.integer "weight"
    t.integer "hp_max", default: 0
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "modified", default: false
    t.datetime "gestation_started_at"
    t.integer "gestation_days_total"
    t.integer "gestation_days_remaining"
    t.jsonb "applied_genes", default: []
    t.jsonb "final_stats", default: {}
    t.integer "gestation_tube"
    t.index ["user_id"], name: "index_embryos_on_user_id"
  end

  create_table "enemies", force: :cascade do |t|
    t.string "enemy_type"
    t.integer "number"
    t.integer "hp_current"
    t.integer "hp_max"
    t.integer "shield_current"
    t.integer "shield_max"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "vitesse"
  end

  create_table "enemy_skills", force: :cascade do |t|
    t.bigint "enemy_id", null: false
    t.bigint "skill_id", null: false
    t.integer "mastery"
    t.integer "bonus"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enemy_id"], name: "index_enemy_skills_on_enemy_id"
    t.index ["skill_id"], name: "index_enemy_skills_on_skill_id"
  end

  create_table "equipments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "slot"
    t.string "name"
    t.text "effect"
    t.boolean "equipped", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_equipments_on_user_id"
  end

  create_table "genes", force: :cascade do |t|
    t.string "property", null: false
    t.boolean "positive", default: true, null: false
    t.integer "category", null: false
    t.text "description"
    t.jsonb "skill_bonuses", default: {}
    t.jsonb "stats_bonuses", default: {}
    t.jsonb "special_traits", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "genetic_statistics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "embryos_created", default: 0
    t.integer "embryos_recycled", default: 0
    t.integer "traits_applications_success", default: 0
    t.integer "traits_applications_partial", default: 0
    t.integer "traits_applications_failed", default: 0
    t.integer "gestations_completed", default: 0
    t.integer "clones_created", default: 0
    t.integer "clones_failed", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_genetic_statistics_on_user_id"
  end

  create_table "goods_crates", force: :cascade do |t|
    t.string "content"
    t.integer "quantity"
    t.string "origin_planet"
    t.integer "price_per_crate"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_goods_crates_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "headquarter_inventory_objects", force: :cascade do |t|
    t.bigint "headquarter_id", null: false
    t.bigint "inventory_object_id", null: false
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["headquarter_id"], name: "index_headquarter_inventory_objects_on_headquarter_id"
    t.index ["inventory_object_id"], name: "index_headquarter_inventory_objects_on_inventory_object_id"
  end

  create_table "headquarter_objects", force: :cascade do |t|
    t.string "name", null: false
    t.integer "quantity", default: 1
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_headquarter_objects_on_user_id"
  end

  create_table "headquarters", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.integer "credits"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "holonew_reads", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "holonew_id", null: false
    t.boolean "read"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["holonew_id"], name: "index_holonew_reads_on_holonew_id"
    t.index ["user_id"], name: "index_holonew_reads_on_user_id"
  end

  create_table "holonews", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "target_user"
    t.string "target_group"
    t.boolean "read", default: false
    t.string "sender_alias"
    t.index ["user_id"], name: "index_holonews_on_user_id"
  end

  create_table "inventory_objects", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.text "description"
    t.integer "price"
    t.string "rarity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "catalog_id"
    t.index ["catalog_id"], name: "index_inventory_objects_on_catalog_id"
  end

  create_table "light_sabers", force: :cascade do |t|
    t.bigint "apprentice_id"
    t.string "name", default: "Sabre laser"
    t.string "color", default: "bleu"
    t.string "crystal", default: "Cristal Kyber"
    t.integer "damage", default: 5
    t.integer "damage_bonus", default: 0
    t.string "special_attribute"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["apprentice_id"], name: "index_light_sabers_on_apprentice_id"
  end

  create_table "pazaak_games", force: :cascade do |t|
    t.bigint "host_id", null: false
    t.bigint "guest_id"
    t.integer "status", default: 0, null: false
    t.integer "current_turn_user_id"
    t.integer "round_number", default: 1, null: false
    t.integer "wins_host", default: 0, null: false
    t.integer "wins_guest", default: 0, null: false
    t.text "host_state", default: "{}", null: false
    t.text "guest_state", default: "{}", null: false
    t.integer "last_drawn_card"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "first_player_id"
    t.index ["first_player_id"], name: "index_pazaak_games_on_first_player_id"
    t.index ["guest_id"], name: "index_pazaak_games_on_guest_id"
    t.index ["host_id"], name: "index_pazaak_games_on_host_id"
  end

  create_table "pazaak_invitations", force: :cascade do |t|
    t.bigint "inviter_id", null: false
    t.bigint "invitee_id", null: false
    t.bigint "pazaak_game_id"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "stake", default: 0, null: false
    t.index ["invitee_id"], name: "index_pazaak_invitations_on_invitee_id"
    t.index ["inviter_id", "invitee_id", "status"], name: "idx_on_inviter_id_invitee_id_status_362b576a3f"
    t.index ["inviter_id"], name: "index_pazaak_invitations_on_inviter_id"
    t.index ["pazaak_game_id"], name: "index_pazaak_invitations_on_pazaak_game_id"
  end

  create_table "pazaak_presences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "last_seen_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_pazaak_presences_on_user_id", unique: true
  end

  create_table "pazaak_stats", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "games_played", default: 0, null: false
    t.integer "games_won", default: 0, null: false
    t.integer "games_lost", default: 0, null: false
    t.integer "rounds_won", default: 0, null: false
    t.integer "rounds_lost", default: 0, null: false
    t.integer "rounds_tied", default: 0, null: false
    t.integer "games_abandoned", default: 0, null: false
    t.integer "best_win_streak", default: 0, null: false
    t.integer "worst_lose_streak", default: 0, null: false
    t.integer "current_win_streak", default: 0, null: false
    t.integer "current_lose_streak", default: 0, null: false
    t.integer "credits_won", default: 0, null: false
    t.integer "credits_lost", default: 0, null: false
    t.integer "stake_max", default: 0, null: false
    t.integer "stake_min", default: 0, null: false
    t.integer "stake_sum", default: 0, null: false
    t.integer "stake_count", default: 0, null: false
    t.integer "playmate_user_id"
    t.integer "nemesis_user_id"
    t.integer "victim_user_id"
    t.jsonb "opponent_counters", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_pazaak_stats_on_user_id", unique: true
  end

  create_table "pet_inventory_objects", force: :cascade do |t|
    t.bigint "pet_id", null: false
    t.bigint "inventory_object_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_object_id"], name: "index_pet_inventory_objects_on_inventory_object_id"
    t.index ["pet_id"], name: "index_pet_inventory_objects_on_pet_id"
  end

  create_table "pet_skills", force: :cascade do |t|
    t.bigint "pet_id", null: false
    t.bigint "skill_id", null: false
    t.integer "mastery", default: 0, null: false
    t.integer "bonus", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pet_id"], name: "index_pet_skills_on_pet_id"
    t.index ["skill_id"], name: "index_pet_skills_on_skill_id"
  end

  create_table "pet_statuses", force: :cascade do |t|
    t.bigint "pet_id", null: false
    t.bigint "status_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pet_id"], name: "index_pet_statuses_on_pet_id"
    t.index ["status_id"], name: "index_pet_statuses_on_status_id"
  end

  create_table "pets", force: :cascade do |t|
    t.string "name"
    t.string "race"
    t.integer "hp_current"
    t.integer "hp_max"
    t.integer "damage_1"
    t.integer "damage_2"
    t.string "weapon_1"
    t.string "weapon_2"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.string "category"
    t.string "url_image"
    t.integer "damage_1_bonus", default: 0, null: false
    t.integer "damage_2_bonus", default: 0, null: false
    t.integer "mood", default: 2, null: false
    t.integer "loyalty", default: 2, null: false
    t.integer "hunger", default: 2, null: false
    t.integer "fatigue", default: 2, null: false
    t.bigint "status_id", default: 40, null: false
    t.integer "size", default: 100, null: false
    t.integer "weight", default: 50, null: false
    t.integer "vitesse"
    t.integer "shield_current", default: 0
    t.integer "shield_max", default: 0
    t.boolean "creature", default: false, null: false
    t.integer "age", default: 1, null: false
    t.boolean "force"
    t.jsonb "special_traits", default: []
    t.bigint "origin_embryo_id"
    t.index ["origin_embryo_id"], name: "index_pets_on_origin_embryo_id"
    t.index ["status_id"], name: "index_pets_on_status_id"
  end

  create_table "races", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ship_objects", force: :cascade do |t|
    t.bigint "ship_id", null: false
    t.string "name"
    t.integer "quantity"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ship_id"], name: "index_ship_objects_on_ship_id"
  end

  create_table "ship_weapons", force: :cascade do |t|
    t.string "name", null: false
    t.string "weapon_type", null: false
    t.integer "quantity_max"
    t.integer "quantity_current"
    t.integer "damage_mastery", default: 0
    t.integer "damage_bonus", default: 0
    t.integer "aim_mastery", default: 0
    t.integer "aim_bonus", default: 0
    t.string "special"
    t.text "description"
    t.bigint "ship_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "price", default: 0, null: false
    t.integer "damage_upgrade_level", default: 0, null: false
    t.integer "aim_upgrade_level", default: 0, null: false
    t.index ["ship_id"], name: "index_ship_weapons_on_ship_id"
  end

  create_table "ships", force: :cascade do |t|
    t.string "name"
    t.integer "price"
    t.string "brand"
    t.string "model"
    t.text "description"
    t.integer "size"
    t.integer "max_passengers"
    t.integer "min_crew"
    t.integer "hp_max"
    t.integer "hp_current"
    t.string "main_weapon"
    t.string "secondary_weapon"
    t.float "hyperdrive_rating"
    t.boolean "backup_hyperdrive", default: false
    t.boolean "active", default: false
    t.integer "parent_ship_id"
    t.bigint "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "shields_disabled", default: false
    t.boolean "controls_ionized", default: false
    t.boolean "weapon_damaged", default: false
    t.boolean "thrusters_damaged", default: false
    t.boolean "hyperdrive_broken", default: false
    t.boolean "depressurized", default: false
    t.boolean "ship_destroyed", default: false
    t.boolean "torpilles"
    t.boolean "missiles"
    t.integer "scale", default: 0, null: false
    t.integer "capacity", default: 0, null: false
    t.integer "used_capacity", default: 0, null: false
    t.integer "thruster_level", default: 0, null: false
    t.integer "hull_level", default: 0, null: false
    t.integer "circuits_level", default: 0, null: false
    t.integer "shield_system_level", default: 0, null: false
    t.integer "hp_max_upgrades", default: 0, null: false
    t.integer "astromech_droids", default: 0, null: false
    t.string "current_damage_cause"
    t.index ["group_id"], name: "index_ships_on_group_id"
    t.index ["parent_ship_id"], name: "index_ships_on_parent_ship_id"
  end

  create_table "ships_skills", force: :cascade do |t|
    t.bigint "ship_id", null: false
    t.bigint "skill_id", null: false
    t.integer "mastery"
    t.integer "bonus"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ship_id"], name: "index_ships_skills_on_ship_id"
    t.index ["skill_id"], name: "index_ships_skills_on_skill_id"
  end

  create_table "skills", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "carac_id"
    t.index ["carac_id"], name: "index_skills_on_carac_id"
  end

  create_table "sphero_skills", force: :cascade do |t|
    t.bigint "sphero_id"
    t.bigint "skill_id"
    t.integer "mastery", null: false
    t.integer "bonus", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["skill_id"], name: "index_sphero_skills_on_skill_id"
    t.index ["sphero_id"], name: "index_sphero_skills_on_sphero_id"
  end

  create_table "spheros", force: :cascade do |t|
    t.string "name", default: "Sphéro-Droïde"
    t.string "category", null: false
    t.integer "quality", null: false
    t.integer "medipacks", default: 0
    t.integer "hp_current", default: 20
    t.integer "hp_max", default: 20
    t.integer "shield_current", default: 0
    t.integer "shield_max", default: 0
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: false
    t.index ["user_id"], name: "index_spheros_on_user_id"
  end

  create_table "statuses", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "endpoint"
    t.text "p256dh"
    t.text "auth"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "sender_id"
    t.integer "receiver_id"
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_caracs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "carac_id", null: false
    t.integer "mastery"
    t.integer "bonus"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["carac_id"], name: "index_user_caracs_on_carac_id"
    t.index ["user_id"], name: "index_user_caracs_on_user_id"
  end

  create_table "user_genes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "gene_id", null: false
    t.integer "level", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gene_id"], name: "index_user_genes_on_gene_id"
    t.index ["user_id", "gene_id"], name: "index_user_genes_on_user_id_and_gene_id", unique: true
    t.index ["user_id"], name: "index_user_genes_on_user_id"
  end

  create_table "user_inventory_objects", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "inventory_object_id", null: false
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_object_id"], name: "index_user_inventory_objects_on_inventory_object_id"
    t.index ["user_id", "inventory_object_id"], name: "idx_on_user_id_inventory_object_id_b86c0a23ac", unique: true
    t.index ["user_id"], name: "index_user_inventory_objects_on_user_id"
  end

  create_table "user_skills", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "skill_id", null: false
    t.integer "mastery", default: 0, null: false
    t.integer "bonus", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["skill_id"], name: "index_user_skills_on_skill_id"
    t.index ["user_id"], name: "index_user_skills_on_user_id"
  end

  create_table "user_statuses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "status_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status_id"], name: "index_user_statuses_on_status_id"
    t.index ["user_id"], name: "index_user_statuses_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "credits", default: 0
    t.string "username"
    t.bigint "group_id", null: false
    t.integer "hp_max"
    t.integer "hp_current"
    t.boolean "shield_state"
    t.integer "shield_max"
    t.integer "shield_current"
    t.bigint "race_id"
    t.bigint "classe_perso_id"
    t.integer "xp", default: 0
    t.integer "total_xp", default: 0
    t.boolean "robustesse", default: false
    t.boolean "homeopathie", default: false
    t.integer "patch"
    t.boolean "echani_shield_state"
    t.integer "echani_shield_current"
    t.integer "echani_shield_max"
    t.boolean "luck", default: false
    t.bigint "pet_id"
    t.integer "pet_action_points", default: 10
    t.integer "hp_bonus"
    t.integer "active_injection"
    t.integer "active_implant"
    t.integer "vitesse"
    t.text "notes"
    t.string "sex"
    t.integer "age"
    t.integer "height"
    t.integer "weight"
    t.integer "dark_side_points", default: 0
    t.integer "cyber_points", default: 0
    t.boolean "junkie", default: false
    t.integer "study_points", default: 0
    t.jsonb "pazaak_deck", default: []
    t.jsonb "discovered_drinks", default: []
    t.boolean "chatouille_enabled", default: false, null: false
    t.index ["classe_perso_id"], name: "index_users_on_classe_perso_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["group_id"], name: "index_users_on_group_id"
    t.index ["pet_id"], name: "index_users_on_pet_id"
    t.index ["race_id"], name: "index_users_on_race_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "apprentice_caracs", "apprentices"
  add_foreign_key "apprentice_caracs", "caracs"
  add_foreign_key "apprentice_skills", "apprentices"
  add_foreign_key "apprentice_skills", "skills"
  add_foreign_key "apprentices", "pets"
  add_foreign_key "apprentices", "users"
  add_foreign_key "building_pets", "buildings"
  add_foreign_key "building_pets", "pets"
  add_foreign_key "buildings", "headquarters"
  add_foreign_key "buildings", "pets", column: "chief_pet_id"
  add_foreign_key "chatouille_states", "users"
  add_foreign_key "crew_members", "ships"
  add_foreign_key "defenses", "headquarters"
  add_foreign_key "embryo_skills", "embryos"
  add_foreign_key "embryo_skills", "skills"
  add_foreign_key "embryos", "users"
  add_foreign_key "enemy_skills", "enemies"
  add_foreign_key "enemy_skills", "skills"
  add_foreign_key "equipments", "users"
  add_foreign_key "genetic_statistics", "users"
  add_foreign_key "goods_crates", "users"
  add_foreign_key "headquarter_inventory_objects", "headquarters"
  add_foreign_key "headquarter_inventory_objects", "inventory_objects"
  add_foreign_key "headquarter_objects", "users"
  add_foreign_key "holonew_reads", "holonews"
  add_foreign_key "holonew_reads", "users"
  add_foreign_key "holonews", "users"
  add_foreign_key "light_sabers", "apprentices"
  add_foreign_key "pazaak_games", "users", column: "guest_id"
  add_foreign_key "pazaak_games", "users", column: "host_id"
  add_foreign_key "pazaak_invitations", "pazaak_games"
  add_foreign_key "pazaak_invitations", "users", column: "invitee_id"
  add_foreign_key "pazaak_invitations", "users", column: "inviter_id"
  add_foreign_key "pazaak_presences", "users"
  add_foreign_key "pazaak_stats", "users"
  add_foreign_key "pet_inventory_objects", "inventory_objects"
  add_foreign_key "pet_inventory_objects", "pets"
  add_foreign_key "pet_skills", "pets"
  add_foreign_key "pet_skills", "skills"
  add_foreign_key "pet_statuses", "pets"
  add_foreign_key "pet_statuses", "statuses"
  add_foreign_key "pets", "statuses"
  add_foreign_key "ship_objects", "ships"
  add_foreign_key "ship_weapons", "ships"
  add_foreign_key "ships", "groups"
  add_foreign_key "ships", "ships", column: "parent_ship_id"
  add_foreign_key "ships_skills", "ships"
  add_foreign_key "ships_skills", "skills"
  add_foreign_key "skills", "caracs"
  add_foreign_key "sphero_skills", "skills"
  add_foreign_key "sphero_skills", "spheros"
  add_foreign_key "spheros", "users"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "user_caracs", "caracs"
  add_foreign_key "user_caracs", "users"
  add_foreign_key "user_genes", "genes"
  add_foreign_key "user_genes", "users"
  add_foreign_key "user_inventory_objects", "inventory_objects"
  add_foreign_key "user_inventory_objects", "users"
  add_foreign_key "user_skills", "skills"
  add_foreign_key "user_skills", "users"
  add_foreign_key "user_statuses", "statuses"
  add_foreign_key "user_statuses", "users"
  add_foreign_key "users", "classe_persos"
  add_foreign_key "users", "groups"
  add_foreign_key "users", "pets"
  add_foreign_key "users", "races"
end
