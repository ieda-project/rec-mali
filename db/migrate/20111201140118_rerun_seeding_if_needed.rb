class RerunSeedingIfNeeded < ActiveRecord::Migration
  def self.up
    if Illness.count > 0
      ActiveRecord::Base.subclasses.each &:reset_column_information
      load "#{File.dirname(__FILE__)}/../seeds.rb"
    end
  end

  def self.down
    # Nothing to do.
  end
end
