class AddOtherProblemsToDiags < ActiveRecord::Migration
  def self.up
    add_column :diagnostics, :other_problems, :text
  end

  def self.down
    remove_column :diagnostics, :other_problems
  end
end
