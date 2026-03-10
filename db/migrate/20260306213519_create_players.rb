class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.integer :status, default: 0
      t.string :type, default: :Player.to_s
      t.string :alias, default: :guest
      t.string :api_key, null: false
      t.belongs_to :active_legend, null: true

      t.timestamps
    end

    add_index :players, :status
    add_index :players, :api_key
  end
end
