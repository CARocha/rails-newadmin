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

ActiveRecord::Schema[8.1].define(version: 2026_10_18_000002) do
  create_table "rails_newadmin_admin_sessions", force: :cascade do |t|
    t.integer "admin_user_id", null: false
    t.string "token_digest", null: false
    t.datetime "last_seen_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_rails_newadmin_admin_sessions_on_admin_user_id"
    t.index ["token_digest"], name: "index_rails_newadmin_admin_sessions_on_token_digest", unique: true
  end

  create_table "rails_newadmin_admin_users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.boolean "active", default: true, null: false
    t.boolean "staff", default: false, null: false
    t.boolean "superuser", default: false, null: false
    t.string "locale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_rails_newadmin_admin_users_on_email_address", unique: true
  end

  create_table "rails_newadmin_group_permissions", force: :cascade do |t|
    t.integer "group_id", null: false
    t.integer "permission_id", null: false
    t.index ["group_id", "permission_id"], name: "idx_on_group_id_permission_id_4d46478315", unique: true
    t.index ["group_id"], name: "index_rails_newadmin_group_permissions_on_group_id"
    t.index ["permission_id"], name: "index_rails_newadmin_group_permissions_on_permission_id"
  end

  create_table "rails_newadmin_groups", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_rails_newadmin_groups_on_name", unique: true
  end

  create_table "rails_newadmin_memberships", force: :cascade do |t|
    t.integer "admin_user_id", null: false
    t.integer "group_id", null: false
    t.index ["admin_user_id", "group_id"], name: "index_rails_newadmin_memberships_on_admin_user_id_and_group_id", unique: true
    t.index ["admin_user_id"], name: "index_rails_newadmin_memberships_on_admin_user_id"
    t.index ["group_id"], name: "index_rails_newadmin_memberships_on_group_id"
  end

  create_table "rails_newadmin_permissions", force: :cascade do |t|
    t.string "resource_key", null: false
    t.string "action", null: false
    t.boolean "active", default: true, null: false
    t.index ["resource_key", "action"], name: "index_rails_newadmin_permissions_on_resource_key_and_action", unique: true
  end

  add_foreign_key "rails_newadmin_admin_sessions", "rails_newadmin_admin_users", column: "admin_user_id"
  add_foreign_key "rails_newadmin_group_permissions", "rails_newadmin_groups", column: "group_id"
  add_foreign_key "rails_newadmin_group_permissions", "rails_newadmin_permissions", column: "permission_id"
  add_foreign_key "rails_newadmin_memberships", "rails_newadmin_admin_users", column: "admin_user_id"
  add_foreign_key "rails_newadmin_memberships", "rails_newadmin_groups", column: "group_id"
end
