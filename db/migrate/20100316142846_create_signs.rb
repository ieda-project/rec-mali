class CreateSigns < ActiveRecord::Migration
  def self.up
    create_table :signs do |t|
      t.references :illness
      t.string :type, :key, :question, :values, :dep
      t.integer :sequence, :min_value, :max_value
      t.timestamps
    end
  end

  def self.down
    drop_table :signs
  end
end
