class FixCacheNames < ActiveRecord::Migration
  def self.up
    # Do not call fill_fields! Do not use save!
    # Model refers to fields that don't exist at this point.

    db = Child.connection
    Child.find_each do |ch|
      cname = ch.name.cacheize
      if ch.cache_name != cname
        # Cache name is surely [a-z] only, no danger of SQL injections.
        db.execute "UPDATE children SET cache_name='#{cname}' WHERE id=#{ch.id}"
      end
    end
  end

  def self.down
  end
end
