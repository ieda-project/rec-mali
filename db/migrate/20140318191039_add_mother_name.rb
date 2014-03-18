class AddMotherName < ActiveRecord::Migration
  def self.up
    add_column :children, :mother, :string
  end

  def self.down
    remove_column :children, :mother
  end
end
