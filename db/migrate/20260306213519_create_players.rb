class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.integer :status, default: 0
      t.timestamps
    end

    add_index :players, :status
  end
end
