class AddStateToDiagnostics < ActiveRecord::Migration
  def self.up
    add_column :diagnostics, :state, :string
  end

  def self.down
    remove_column :diagnostics, :state
  end
end
