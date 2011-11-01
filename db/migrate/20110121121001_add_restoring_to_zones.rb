class AddRestoringToZones < ActiveRecord::Migration
  def self.up
    add_column :zones, :restoring, :boolean
    Zone.connection.execute "UPDATE zones SET restoring='f'"
  end

  def self.down
    remove_column :zones, :restoring
  end
end
