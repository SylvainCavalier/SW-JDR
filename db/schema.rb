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

ActiveRecord::Schema[7.1].define(version: 2024_12_24_005922) do
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

  create_table "classe_persos", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "holonews", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "target_user"
    t.string "target_group"
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
    t.index ["status_id"], name: "index_pets_on_status_id"
  end

  create_table "races", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "skills", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "statuses", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "sender_id"
    t.integer "receiver_id"
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_inventory_objects", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "inventory_object_id", null: false
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_object_id"], name: "index_user_inventory_objects_on_inventory_object_id"
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
    t.index ["classe_perso_id"], name: "index_users_on_classe_perso_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["group_id"], name: "index_users_on_group_id"
    t.index ["pet_id"], name: "index_users_on_pet_id"
    t.index ["race_id"], name: "index_users_on_race_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "holonews", "users"
  add_foreign_key "pet_inventory_objects", "inventory_objects"
  add_foreign_key "pet_inventory_objects", "pets"
  add_foreign_key "pet_skills", "pets"
  add_foreign_key "pet_skills", "skills"
  add_foreign_key "pets", "statuses"
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
