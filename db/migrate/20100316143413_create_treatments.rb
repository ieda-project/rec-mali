class CreateTreatments < ActiveRecord::Migration
  def self.up
    create_table :treatments do |t|
      t.string :key
      t.text :description
      t.timestamps
    end
    add_index :treatments, :key
    
    create_table :classifications_treatments, :id => false do |t|
      t.references :classification, :treatment
    end
  end

  def self.down
    drop_table :treatments
  end
end
