class AddAgeDependency < ActiveRecord::Migration
  def self.up
    child = Diagnostic::AGE_GROUPS.index(:child)
    for tbl in %w(classifications diagnostics signs) do
      add_column tbl, :age_group, :integer
      execute "UPDATE #{tbl} SET age_group='#{child}'"
    end
  end

  def self.down
    for tbl in %w(classifications diagnostics signs) do
      remove_column tbl, :age_group
    end
  end
end
