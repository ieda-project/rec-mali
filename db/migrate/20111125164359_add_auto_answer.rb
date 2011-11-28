class AddAutoAnswer < ActiveRecord::Migration
  def self.up
    add_column :signs, :auto, :text
  end

  def self.down
    remove_column :signs, :auto
  end
end
