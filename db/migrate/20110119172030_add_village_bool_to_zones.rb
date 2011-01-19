class AddVillageBoolToZones < ActiveRecord::Migration
  def self.up
    Zone.connection.execute "ALTER TABLE zones ADD village boolean"
    Zone.connection.execute "UPDATE zones SET village='f'"
    Zone.connection.execute "UPDATE zones SET village='t' WHERE parent_id IN (SELECT id FROM zones WHERE point='t')"
  end

  def self.down
  end
end
