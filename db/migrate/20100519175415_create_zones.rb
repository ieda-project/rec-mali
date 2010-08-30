class CreateZones < ActiveRecord::Migration
  def self.up
    create_table :zones do |t|
      t.references :parent
      t.integer :lft, :rgt
      t.string :name
      t.boolean :here, :point
      t.timestamps
    end
  end

  def self.down
    drop_table :zones
  end
end
