class AddAgeDependency < ActiveRecord::Migration
  def self.up
    child = Csps::Age['child']
    for tbl in %w(classifications signs) do
      add_column tbl, :age_group, :integer
      execute "UPDATE #{tbl} SET age_group='#{child}'"
    end
  end

  def self.down
    for tbl in %w(classifications signs) do
      remove_column tbl, :age_group
    end
  end
end
