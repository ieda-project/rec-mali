class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name, :crypted_password
      t.boolean :admin
      t.timestamps

      t.references :zone
      t.string :global_id
    end
  end

  def self.down
    drop_table :users
  end
end
