class CreateDictionaries < ActiveRecord::Migration[8.1]
  def change
    create_table :dictionaries do |t|
      t.belongs_to :story, null: false, foreign_key: true

      t.timestamps
    end
  end
end
