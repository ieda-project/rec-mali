class CreateChildren < ActiveRecord::Migration
  def self.up
    create_table :children do |t|
      t.references :village
      t.string :name
      t.date :born_on
      t.boolean :gender
      t.datetime :last_visit_at

      t.string :photo_file_name, :photo_content_type
      t.integer :photo_file_size

      t.timestamps
      t.string :global_id
      t.boolean :imported, :temporary

      t.boolean :bcg_polio0, :penta1_polio1,
                :penta2_polio2, :penta3_polio3, :measles

      t.string :cache_name
    end
    add_index :children, :global_id
  end

  def self.down
    drop_table :children
  end
end
