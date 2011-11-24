class CreateSerialNumbers < ActiveRecord::Migration
  def self.up
    create_table :serial_numbers do |t|
      t.references :zone
      t.string :model
      t.integer :value, default: 0, null: false
      t.boolean :exported, default: false, null: false
      t.timestamps
    end

    for model in Csps::Exportable.models do
      next unless model.table_exists?
      model.select("DISTINCT zone_id").each do |i|
        SerialNumber.create zone_id: i.zone_id, model: model.name, value: 1
      end
    end
  end

  def self.down
    drop_table :serial_numbers
  end
end
