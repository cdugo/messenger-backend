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

ActiveRecord::Schema[7.2].define(version: 2024_11_19_170050) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "message_reactions", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.bigint "user_id", null: false
    t.string "emoji"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_message_reactions_on_message_id"
    t.index ["user_id"], name: "index_message_reactions_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.bigint "user_id", null: false
    t.bigint "server_id", null: false
    t.bigint "parent_message_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_message_id"], name: "index_messages_on_parent_message_id"
    t.index ["server_id"], name: "index_messages_on_server_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "server_members", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "server_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["server_id"], name: "index_server_members_on_server_id"
    t.index ["user_id", "server_id"], name: "index_server_members_on_user_id_and_server_id", unique: true
    t.index ["user_id"], name: "index_server_members_on_user_id"
  end

  create_table "server_read_states", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "server_id", null: false
    t.datetime "last_read_at", null: false
    t.integer "unread_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["server_id"], name: "index_server_read_states_on_server_id"
    t.index ["user_id", "server_id"], name: "index_server_read_states_on_user_id_and_server_id", unique: true
    t.index ["user_id"], name: "index_server_read_states_on_user_id"
  end

  create_table "servers", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "owner_id", null: false
    t.index ["owner_id"], name: "index_servers_on_owner_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "email"
    t.boolean "is_active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "message_reactions", "messages"
  add_foreign_key "message_reactions", "users"
  add_foreign_key "messages", "messages", column: "parent_message_id"
  add_foreign_key "messages", "servers"
  add_foreign_key "messages", "users"
  add_foreign_key "server_members", "servers"
  add_foreign_key "server_members", "users"
  add_foreign_key "server_read_states", "servers"
  add_foreign_key "server_read_states", "users"
  add_foreign_key "servers", "users", column: "owner_id"
end
