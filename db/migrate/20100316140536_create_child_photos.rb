class CreateChildPhotos < ActiveRecord::Migration
  def self.up
    create_table :child_photos do |t|
      t.string :global_id
      t.references :child
      t.timestamps
    end
    add_index :child_photos, :global_id
    add_index :child_photos, :child_id
  end

  def self.down
    drop_table :child_photos
  end
end
