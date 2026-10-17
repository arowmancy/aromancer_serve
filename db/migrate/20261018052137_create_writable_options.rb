class CreateWritableOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :writable_options do |t|
      t.belongs_to :writable, null: false, foreign_key: true
      t.string :uuid, null: false
      t.string :payload

      t.timestamps
    end
  end
end
