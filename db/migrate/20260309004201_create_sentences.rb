class CreateSentences < ActiveRecord::Migration[8.1]
  def change
    create_table :sentences do |t|
      t.integer :value, default: 0
      t.belongs_to :signature, null: true
      t.belongs_to :author, null: false
      t.belongs_to :chapter, null: false, foreign_key: true

      t.timestamps
    end

    add_index :sentences, [:signature_id, :author_id, :chapter_id], unique: true
  end
end
