class AddDistinctToQueries < ActiveRecord::Migration
  def self.up
    add_column :queries, :distinct, :string
  end

  def self.down
    remove_column :queries, :distinct
  end
end
