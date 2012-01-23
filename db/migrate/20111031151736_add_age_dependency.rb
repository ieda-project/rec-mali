class AddAgeDependency < ActiveRecord::Migration
  def self.up
    child = Csps::Age['child']
    for tbl in %w(classifications signs) do
      add_column tbl, :age_group, :integer
      execute "UPDATE #{tbl} SET age_group='#{child}'"
    end
    add_column :diagnostics, :saved_age_group, :integer
    execute "UPDATE diagnostics SET saved_age_group='#{child}'"
  end

  def self.down
    remove_column :diagnostics, :saved_age_group
    for tbl in %w(classifications signs) do
      remove_column tbl, :age_group
    end
  end
end
