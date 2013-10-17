class AddGroupToQueries < ActiveRecord::Migration
  def self.up
    add_column :queries, :group_title, :string
  end

  def self.down
    remove_column :queries, :group_title
  end
end
