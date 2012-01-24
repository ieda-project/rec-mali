class RerunSeedingIfNeeded < ActiveRecord::Migration
  def self.up
    if Illness.any?
      ActiveRecord::Base.subclasses.each &:reset_column_information
      load "#{File.dirname(__FILE__)}/../seeds.rb"
    end
  end

  def self.down
    # Nothing to do.
  end
end
