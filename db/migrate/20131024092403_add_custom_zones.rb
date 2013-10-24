class AddCustomZones < ActiveRecord::Migration
  def self.up
    add_column :zones, :custom, :boolean
    add_column :zones, :exported_at, :datetime
    Zone.update_all custom: false
  end

  def self.down
    remove_column :zones, :custom
    remove_column :zones, :exported_at
  end
end
