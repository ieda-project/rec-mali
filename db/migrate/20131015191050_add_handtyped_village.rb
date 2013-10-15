class AddHandtypedVillage < ActiveRecord::Migration
  def self.up
    add_column :children, :village_name, :string
  end

  def self.down
    remove_column :children, :village_name
  end
end
