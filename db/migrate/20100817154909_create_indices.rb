class CreateIndices < ActiveRecord::Migration
  def self.up
    create_table :indices do |t|
      t.float :x, :y
      t.integer :name
      t.boolean :for_boys, :above_2yrs
      t.timestamps
    end
  end

  def self.down
    drop_table :indices
  end
end
