class CreateClassifications < ActiveRecord::Migration
  def self.up
    create_table :classifications do |t|
      t.timestamps
      t.references :illness
      t.string :key, :name
      t.text :equation, :treatment
      t.boolean :in_imci, :in_gdt
      t.integer :level
    end
    add_index :classifications, :illness_id

    create_table :classifications_signs, :id => false do |t|
      t.references :classification, :sign
    end

    create_table :classifications_diagnostics, :id => false do |t|
      t.references :classification, :diagnostic
    end
  end

  def self.down
    drop_table :classifications_diagnostics
    drop_table :classifications_signs
    drop_table :classifications
  end
end
