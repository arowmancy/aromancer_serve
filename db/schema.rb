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

ActiveRecord::Schema[8.1].define(version: 2026_03_07_224755) do
  create_table "legends", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "player_count", default: 2
    t.integer "status", default: 0
    t.integer "story_count", default: 1
    t.datetime "updated_at", null: false
    t.integer "winner_id"
    t.index ["status"], name: "index_legends_on_status"
    t.index ["winner_id"], name: "index_legends_on_winner_id"
  end

  create_table "player_legends", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "legend_id", null: false
    t.integer "player_id", null: false
    t.datetime "updated_at", null: false
    t.index ["legend_id"], name: "index_player_legends_on_legend_id"
    t.index ["player_id", "legend_id"], name: "index_player_legends_on_player_id_and_legend_id", unique: true
    t.index ["player_id"], name: "index_player_legends_on_player_id"
  end

  create_table "players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_players_on_status"
  end

  create_table "stories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "legend_id", null: false
    t.datetime "updated_at", null: false
    t.integer "winner_id"
    t.index ["legend_id"], name: "index_stories_on_legend_id"
    t.index ["winner_id"], name: "index_stories_on_winner_id"
  end

  add_foreign_key "player_legends", "legends"
  add_foreign_key "player_legends", "players"
  add_foreign_key "stories", "legends"
end
