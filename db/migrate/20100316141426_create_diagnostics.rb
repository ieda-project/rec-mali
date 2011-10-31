class CreateDiagnostics < ActiveRecord::Migration
  def self.up
    create_table :diagnostics do |t|
      t.string :child_global_id, :author_global_id
      t.string :type
      t.datetime :done_on
      t.integer :mac
      t.float :height, :weight, :temperature
      t.text :comments
      t.string :failed_classifications
      t.timestamps

      t.references :zone
      t.string :global_id
    end
    add_index :diagnostics, [:type, :id]
    add_index :diagnostics, [:type, :global_id]
    add_index :diagnostics, :child_global_id
    add_index :diagnostics, :author_global_id
  end

  def self.down
    drop_table :diagnostics
  end
end
