class CreateChildren < ActiveRecord::Migration
  def self.up
    create_table :children do |t|
      t.string :first_name
      t.string :last_name
      t.date :born_on
      t.boolean :gender
      t.timestamps

      t.string :global_id
      t.boolean :imported
    end
    add_index :children, :global_id
  end

  def self.down
    drop_table :children
  end
end
