class CreateDiagnostics < ActiveRecord::Migration
  def self.up
    create_table :diagnostics do |t|
      t.string :type
      t.references :child, :author
      t.date :done_on
      t.integer :height, :mac
      t.float :weight
      t.text :comments
      t.string :failed_classifications
      t.timestamps

      t.string :global_id
      t.boolean :imported
    end
    add_index :diagnostics, [:type, :id]
    add_index :diagnostics, [:type, :global_id]
    add_index :diagnostics, :child_id
    add_index :diagnostics, :author_id
  end

  def self.down
    drop_table :diagnostics
  end
end
