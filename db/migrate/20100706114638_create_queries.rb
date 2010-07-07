class CreateQueries < ActiveRecord::Migration
  def self.up
    create_table :queries do |t|
      t.string :title, :klass
      t.integer :case_status
      t.text :conditions
      t.datetime :last_run_at
      t.timestamps
    end
  end

  def self.down
    drop_table :queries
  end
end
