class CreateMedicines < ActiveRecord::Migration
  def self.up
    create_table :medicines do |t|
      t.timestamps
      t.string :name, :key, :unit
      t.text :formula, :code
    end
  end

  def self.down
    drop_table :medicines
  end
end
