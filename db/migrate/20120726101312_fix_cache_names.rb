class FixCacheNames < ActiveRecord::Migration
  def self.up
    Child.find_each do |ch|
      ch.send :fill_cache_fields
      ch.save if ch.changed?
    end
  end

  def self.down
  end
end
