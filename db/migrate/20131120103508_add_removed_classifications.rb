class AddRemovedClassifications < ActiveRecord::Migration
  def self.up
    add_column :classifications, :removed, :boolean
    add_index :classifications, [:age_group, :removed]
  end

  def self.down
    remove_column :classifications, :removed, :boolean
  end
end
