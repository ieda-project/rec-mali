class AddOrdonnance < ActiveRecord::Migration
  def self.up
    add_column :diagnostics, :ordonnance, :string
    add_column :prescriptions, :mandatory, :boolean
  end

  def self.down
    remove_column :diagnostics, :ordonnance
    remove_column :prescriptions, :mandatory
  end
end
