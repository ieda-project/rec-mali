class CreateTreatments < ActiveRecord::Migration
  def self.up
    create_table :treatments do |t|
      t.timestamps
      t.belongs_to :classification
      t.string :name
      t.text :description
    end
    remove_column :classifications, :treatment
  end

  def self.down
    add_column :classifications, :treatment, :text
    drop_table :treatments
  end
end
