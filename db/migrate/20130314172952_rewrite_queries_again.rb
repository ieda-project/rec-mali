class RewriteQueriesAgain < ActiveRecord::Migration
  def self.up
    rewrite do |c|
      c['attribute'].sub! /^classifications\./, 'results.classification.'
    end
  end

  def self.down
    rewrite do |c|
      c['attribute'].sub! /^results\.classification\./, 'classifications.'
    end
  end

  def self.rewrite &blk
    Query.all.each do |q|
      arr = Array(JSON.parse(q.conditions))
      arr.each do |c|
        blk.(c) if c['type'] == 'field'
      end
      q.update_attribute :conditions, arr.to_json
    end
  end
end
