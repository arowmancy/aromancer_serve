class CreateLegends < ActiveRecord::Migration[8.1]
  def change
    create_table :legends do |t|
      t.integer :status, default: 0
      t.integer :story_count, default: 1
      t.integer :player_count, default: 2
      t.belongs_to :winner, null: true

      t.timestamps
    end

    add_index :legends, :status
  end
end
