class CreatePlayerLegends < ActiveRecord::Migration[8.1]
  def change
    create_table :player_legends do |t|
      t.belongs_to :player, null: false, foreign_key: true
      t.belongs_to :legend, null: false, foreign_key: true

      t.timestamps
    end

    add_index :player_legends, [:player_id, :legend_id], unique: true
  end
end
