class CreateSites < ActiveRecord::Migration
  def self.up
    create_table :sites do |t|
      t.text :locations
      t.string :phone
      t.timestamps

      t.string :global_id
    end
  end

  def self.down
    drop_table :sites
  end
end
