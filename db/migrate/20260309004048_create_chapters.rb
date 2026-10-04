class CreateChapters < ActiveRecord::Migration[8.1]
  def change
    create_table :chapters do |t|
      t.boolean :is_final, default: false
      t.belongs_to :story, null: false, foreign_key: true
      t.belongs_to :turn_player, null: false

      t.timestamps
    end
  end
end
