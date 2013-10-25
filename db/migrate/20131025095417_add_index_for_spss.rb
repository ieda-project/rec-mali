class AddIndexForSpss < ActiveRecord::Migration
  def self.up
    add_index :diagnostics, [:saved_age_group, :state]
  end

  def self.down
    remove_index :diagnostics, [:saved_age_group, :state]
  end
end
