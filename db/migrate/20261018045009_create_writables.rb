class CreateWritables < ActiveRecord::Migration[8.1]
  def change
    create_table :writables do |t|
      t.string :uuid, null: false
      t.belongs_to :word, null: false, foreign_key: true
      t.belongs_to :player_legend, null: false, foreign_key: true

      t.timestamps
    end
  end
end
