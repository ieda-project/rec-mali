class AddPasswordExpiration < ActiveRecord::Migration
  def self.up
    add_column :users, :password_expired_at, :timestamp
  end

  def self.down
    remove_column :users, :password_expired_at
  end
end
