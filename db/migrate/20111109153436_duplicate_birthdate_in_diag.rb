class DuplicateBirthdateInDiag < ActiveRecord::Migration
  def self.up
    add_column :diagnostics, :born_on, :date
    Diagnostic.includes(:child).find_each do |diag|
      diag.update_attribute :born_on, diag.child.born_on
    end
  end

  def self.down
    remove_column :diagnostics, :born_on
  end
end
