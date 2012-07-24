class RewriteQueries < ActiveRecord::Migration
  def self.up
    Query.where(klass: 'Child').update_all klass: 'Diagnostic'
    rewrite do |c|
      case c['type']
        when 'age'
          c.delete 'attribute'
          c['value'] = c['value'].to_i
        when 'ruby'
          field = c.delete 'field'
          if field =~ /sign_answers\[(.*)\]/
            c['type'] = 'sign'
            c['sign'] = $1
          else
            c['type'] = 'field'
            c['attribute'] = "#{field}.name"
            c['operator'] = '=' if c['operator'] == 'include?'
          end
        when 'boolean'
          c['attribute'] = 'child.gender' if c['attribute'] == 'gender'
          c['value'] = (c['value'] == 'true')
          c.delete 'operator'
      end
    end
  end

  def self.down
    Query.where(klass: 'Diagnostic').update_all klass: 'Child'
    rewrite do |c|
      case c['type']
        when 'age'
          c['attribute'] = 'born_on'
          c['value'] = c['value'].to_s
        when 'field'
          c['type'] = 'ruby'
          c['field'] = c.delete('field').sub(/\.name$/, '')
          c['operator'] = 'include?' if c['operator'] == '='
        when 'sign'
          c['type'] = 'ruby'
          c['field'] = "sign_answers[#{c.delete('sign')}]"
        when 'boolean'
          c['attribute'] = 'gender' if c['attribute'] == 'child.gender'
          c['value'] = c['value'].to_s
          c['operator'] = '='
      end
    end
  end

  def self.rewrite &blk
    Query.all.each do |q|
      arr = Array(JSON.parse(q.conditions))
      arr.each &blk
      q.update_attribute :conditions, arr.to_json
    end
  end
end
