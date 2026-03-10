class CreatePlayerWords < ActiveRecord::Migration[8.1]
  def change
    create_table :player_words do |t|
      t.belongs_to :player, null: false, foreign_key: true
      t.belongs_to :chapter, null: false, foreign_key: true
      t.belongs_to :word, null: false, foreign_key: true

      t.timestamps
    end

    add_index :player_words, [:player_id, :chapter_id, :word_id], unique: true
  end
end
