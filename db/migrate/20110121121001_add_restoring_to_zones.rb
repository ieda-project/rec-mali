class AddRestoringToZones < ActiveRecord::Migration
  def self.up
    Zone.connection.execute "ALTER TABLE zones ADD restoring boolean"
    Zone.connection.execute "UPDATE zones SET restoring='f'"
  end

  def self.down
  end
end
