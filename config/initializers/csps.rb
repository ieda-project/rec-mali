load 'monkey_patches.rb'

module Csps
  SITE = `hostname -s`.chomp
  def self.site; SITE; end
end

ActiveRecord::Relation.send :include, Csps::Relation
