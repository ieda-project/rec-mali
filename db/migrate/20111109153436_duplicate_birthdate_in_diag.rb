class DuplicateBirthdateInDiag < ActiveRecord::Migration
  def self.up
    add_column :diagnostics, :born_on, :date
  end

  def self.down
    remove_column :diagnostics, :born_on
  end
end
