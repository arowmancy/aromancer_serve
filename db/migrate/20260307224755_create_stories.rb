class CreateStories < ActiveRecord::Migration[8.1]
  def change
    create_table :stories do |t|
      t.belongs_to :legend, null: false, foreign_key: true
      t.belongs_to :winner, null: true
      t.belongs_to :dealer, null: false

      t.timestamps
    end
  end
end
