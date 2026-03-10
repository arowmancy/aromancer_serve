class CreateSentenceWords < ActiveRecord::Migration[8.1]
  def change
    create_table :sentence_words do |t|
      t.belongs_to :sentence, null: false, foreign_key: true
      t.belongs_to :word, null: false, foreign_key: true

      t.timestamps
    end

    add_index :sentence_words, [:sentence_id, :word_id], unique: true
  end
end
