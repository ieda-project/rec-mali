class AddSd3ToIndices < ActiveRecord::Migration
  def self.up
    add_column :indices, :sd3neg, :float
    add_column :indices, :sd2neg, :float
    add_column :indices, :sd1neg, :float
    add_column :indices, :sd1, :float
    add_column :indices, :sd2, :float
    add_column :indices, :sd3, :float
  end

  def self.down
    remove_column :indices, :sd3neg
    remove_column :indices, :sd2neg
    remove_column :indices, :sd1neg
    remove_column :indices, :sd1
    remove_column :indices, :sd2
    remove_column :indices, :sd3
  end
end
