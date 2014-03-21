class AddRetiredSigns < ActiveRecord::Migration
  def self.up
    add_column :signs, :retired, :boolean
    add_index :signs, :retired
  end

  def self.down
    remove_column :signs, :retired
  end
end
