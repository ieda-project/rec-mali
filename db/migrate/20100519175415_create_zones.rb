class CreateZones < ActiveRecord::Migration
  def self.up
    create_table :zones do |t|
      t.references :parent
      t.integer :lft, :rgt
      t.string :name
      t.boolean :here, :accessible, :point
      t.datetime :last_import_at, :last_export_at
      t.timestamps
    end
  end

  def self.down
    drop_table :zones
  end
end
