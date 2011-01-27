class CreateSerialNumbers < ActiveRecord::Migration
  def self.up
    create_table :serial_numbers do |t|
      t.references :zone
      t.string :model
      t.integer :value, default: 0, null: false
      t.boolean :exported
      t.timestamps
    end
  end

  def self.down
    drop_table :serial_numbers
  end
end
