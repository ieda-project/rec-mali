class AddTreatmentToResults < ActiveRecord::Migration
  def self.up
    add_column :results, :treatment_id, :int
  end

  def self.down
    remove_column :results, :treatment_id
  end
end
