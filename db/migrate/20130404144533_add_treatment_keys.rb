class AddTreatmentKeys < ActiveRecord::Migration
  def self.up
    add_column :treatments, :key, :string
  end

  def self.down
    add_column :treatments, :key
  end
end
