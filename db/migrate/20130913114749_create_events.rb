class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.timestamps
      t.belongs_to :user
      t.integer :kind
    end

    add_index :events, :kind
  end

  def self.down
    drop_table :events
  end
end
