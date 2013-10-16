class AddZscoreToIndices < ActiveRecord::Migration
  def self.up
    add_column :indices, :sd4neg, :float
    add_column :indices, :sd4, :float
  end

  def self.down
    remove_column :indices, :sd4neg
    remove_column :indices, :sd4
  end
end
