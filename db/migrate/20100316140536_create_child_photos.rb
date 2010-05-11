class CreateChildPhotos < ActiveRecord::Migration
  def self.up
    create_table :child_photos do |t|
      t.references :child
      t.timestamps

      t.string :global_id
      t.boolean :imported
    end
    add_index :child_photos, :global_id
    add_index :child_photos, :child_id
  end

  def self.down
    drop_table :child_photos
  end
end
