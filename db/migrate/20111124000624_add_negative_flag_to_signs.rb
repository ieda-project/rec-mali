class AddNegativeFlagToSigns < ActiveRecord::Migration
  def self.up
    add_column :signs, :negative, :boolean
  end

  def self.down
    remove_column :signs, :negative
  end
end
