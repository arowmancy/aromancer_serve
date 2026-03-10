class CreateScrollWords < ActiveRecord::Migration[8.1]
  def change
    create_table :scroll_words do |t|
      t.belongs_to :chapter, null: false, foreign_key: true
      t.belongs_to :word, null: false, foreign_key: true

      t.timestamps
    end

    add_index :scroll_words, [:chapter_id, :word_id], unique: true
  end
end
