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

ActiveRecord::Schema[8.1].define(version: 2026_03_12_190403) do
  create_table "chapters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "dealer_id", null: false
    t.boolean "is_final", default: false
    t.integer "story_id", null: false
    t.integer "turn_player_id", null: false
    t.datetime "updated_at", null: false
    t.index ["dealer_id"], name: "index_chapters_on_dealer_id"
    t.index ["story_id"], name: "index_chapters_on_story_id"
    t.index ["turn_player_id"], name: "index_chapters_on_turn_player_id"
  end

  create_table "dictionaries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "story_id", null: false
    t.datetime "updated_at", null: false
    t.index ["story_id"], name: "index_dictionaries_on_story_id"
  end

  create_table "entries", force: :cascade do |t|
    t.integer "action", default: 0
    t.integer "chapter_id", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.integer "player_id"
    t.datetime "updated_at", null: false
    t.integer "word_id"
    t.index ["chapter_id"], name: "index_entries_on_chapter_id"
    t.index ["player_id"], name: "index_entries_on_player_id"
    t.index ["word_id"], name: "index_entries_on_word_id"
  end

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

  create_table "player_words", force: :cascade do |t|
    t.integer "chapter_id", null: false
    t.datetime "created_at", null: false
    t.integer "player_id", null: false
    t.datetime "updated_at", null: false
    t.integer "word_id", null: false
    t.index ["chapter_id"], name: "index_player_words_on_chapter_id"
    t.index ["player_id", "chapter_id", "word_id"], name: "index_player_words_on_player_id_and_chapter_id_and_word_id", unique: true
    t.index ["player_id"], name: "index_player_words_on_player_id"
    t.index ["word_id"], name: "index_player_words_on_word_id"
  end

  create_table "players", force: :cascade do |t|
    t.integer "active_legend_id"
    t.string "alias", default: "guest"
    t.string "api_key", null: false
    t.datetime "created_at", null: false
    t.integer "status", default: 0
    t.string "type", default: "Player"
    t.datetime "updated_at", null: false
    t.index ["active_legend_id"], name: "index_players_on_active_legend_id"
    t.index ["api_key"], name: "index_players_on_api_key"
    t.index ["status"], name: "index_players_on_status"
  end

  create_table "scroll_words", force: :cascade do |t|
    t.integer "chapter_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "word_id", null: false
    t.index ["chapter_id", "word_id"], name: "index_scroll_words_on_chapter_id_and_word_id", unique: true
    t.index ["chapter_id"], name: "index_scroll_words_on_chapter_id"
    t.index ["word_id"], name: "index_scroll_words_on_word_id"
  end

  create_table "sentence_words", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "sentence_id", null: false
    t.datetime "updated_at", null: false
    t.integer "word_id", null: false
    t.index ["sentence_id", "word_id"], name: "index_sentence_words_on_sentence_id_and_word_id", unique: true
    t.index ["sentence_id"], name: "index_sentence_words_on_sentence_id"
    t.index ["word_id"], name: "index_sentence_words_on_word_id"
  end

  create_table "sentences", force: :cascade do |t|
    t.integer "author_id", null: false
    t.integer "chapter_id", null: false
    t.datetime "created_at", null: false
    t.integer "signature_id"
    t.datetime "updated_at", null: false
    t.integer "value", default: 0
    t.index ["author_id"], name: "index_sentences_on_author_id"
    t.index ["chapter_id"], name: "index_sentences_on_chapter_id"
    t.index ["signature_id", "author_id", "chapter_id"], name: "index_sentences_on_signature_id_and_author_id_and_chapter_id", unique: true
    t.index ["signature_id"], name: "index_sentences_on_signature_id"
  end

  create_table "stories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "legend_id", null: false
    t.datetime "updated_at", null: false
    t.integer "winner_id"
    t.index ["legend_id"], name: "index_stories_on_legend_id"
    t.index ["winner_id"], name: "index_stories_on_winner_id"
  end

  create_table "words", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "dictionary_id", null: false
    t.boolean "is_drawn", default: false
    t.integer "order_index", default: 0
    t.integer "style", default: 0
    t.integer "suit"
    t.datetime "updated_at", null: false
    t.integer "value", default: 0
    t.index ["dictionary_id"], name: "index_words_on_dictionary_id"
  end

  add_foreign_key "chapters", "stories"
  add_foreign_key "dictionaries", "stories"
  add_foreign_key "entries", "chapters"
  add_foreign_key "entries", "players"
  add_foreign_key "entries", "words"
  add_foreign_key "player_legends", "legends"
  add_foreign_key "player_legends", "players"
  add_foreign_key "player_words", "chapters"
  add_foreign_key "player_words", "players"
  add_foreign_key "player_words", "words"
  add_foreign_key "scroll_words", "chapters"
  add_foreign_key "scroll_words", "words"
  add_foreign_key "sentence_words", "sentences"
  add_foreign_key "sentence_words", "words"
  add_foreign_key "sentences", "chapters"
  add_foreign_key "stories", "legends"
  add_foreign_key "words", "dictionaries"
end
