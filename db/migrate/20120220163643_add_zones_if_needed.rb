class AddZonesIfNeeded < ActiveRecord::Migration
  def self.up
    if Zone.count > 0 && !Zone.where(name: 'Kaya').any?
      ActiveRecord::Base.subclasses.each &:reset_column_information
      load "#{File.dirname(__FILE__)}/../seeds.rb"
    end
  end

  def self.down
    # Nothing to do.
  end
end
