class CreateWords < ActiveRecord::Migration[8.1]
  def change
    create_table :words do |t|
      t.belongs_to :dictionary, null: false, foreign_key: true
      t.boolean :is_drawn, default: false
      t.integer :suit
      t.integer :order_index, default: 0
      t.integer :value, default: 0
      t.integer :style, default: 0

      t.timestamps
    end
  end
end
