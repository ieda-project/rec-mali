class CreateIllnesses < ActiveRecord::Migration
  def self.up
    create_table :illnesses do |t|
      t.string :key, :name
      t.integer :sequence
      t.timestamps
    end
  end

  def self.down
    drop_table :illnesses
  end
end
