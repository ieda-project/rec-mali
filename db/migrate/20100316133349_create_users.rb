class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name, :login, :crypted_password
      t.boolean :admin
      t.timestamps

      t.string :global_id
      t.boolean :imported
    end
  end

  def self.down
    drop_table :users
  end
end
