class AddAdminAtToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :admin_at, :datetime
    User.where(admin: true).each { |u| u.update_attributes admin_at: u.created_at }
    remove_column :users, :admin
  end

  def self.down
    add_column :users, :admin, :boolean
    User.where('admin_at IS NOT NULL').each { |u| u.update_attributes admin: true }
    remove_column :users, :admin_at
  end
end
