class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      t.belongs_to :chapter, null: false, foreign_key: true
      t.belongs_to :player, null: true, foreign_key: true
      t.belongs_to :word, null: true, foreign_key: true
      t.integer :action, default: 0
      t.string :description, default: ""

      t.timestamps
    end
  end
end
