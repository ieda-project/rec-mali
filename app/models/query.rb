require 'json'

class Query < ActiveRecord::Base
  enum :case_status, %w{all open new closed referred}
  validates_presence_of :title, :case_status, :klass

  def run
    errors, ar_conditions, ar_params = [], [], []
    conditions = JSON.parse(self.conditions)
    conditions.each_pair do |k, data|
      q_attr, operator, value, type = data['attribute'], data['operator'], data['value'], data['type']
      klass = self.klass.constantize
      sql = ["id IN (SELECT #{klass.table_name}.id FROM #{klass.table_name}"]
      q_attr.split('.').each do |path_item|
        reflection = klass.reflect_on_association(path_item.intern)
        case (reflection && reflection.macro)
        when :has_many
          sql << "LEFT JOIN #{reflection.table_name} ON #{klass.table_name}.id = #{reflection.table_name}.#{reflection.primary_key_name}"
          klass = reflection.class_name.constantize
        when :belongs_to
          sql << "LEFT JOIN #{reflection.table_name} ON #{reflection.table_name}.id = #{klass.table_name}.#{reflection.primary_key_name}"
          klass = reflection.class_name.constantize
        when :has_one
          sql << "LEFT JOIN #{reflection.table_name} ON #{reflection.table_name}.#{reflection.primary_key_name} = #{klass.table_name}.id"
          klass = reflection.class_name.constantize
        else
          cols = klass.columns_hash.values
          if cols.map(&:name).include?(path_item)
            col = klass.columns_hash[path_item]
            col_type = type || col.type
            path_item = 'born_on' if path_item == 'age'
            # /UGLY
            sql_cond, sql_params, sql_error = self.send("build_#{col_type.to_s.downcase}_sql", klass, path_item, operator, value)
            sql << "WHERE #{sql_cond}"
            ar_params << sql_params
          else
            raise "Invalid path item '#{path_item}'"
          end
        end
      end
      sql << ')'
      ar_conditions << sql.join("\n")
    end
    ar_conditions = ar_conditions.join(' AND ')
    rs = if ar_conditions.blank?
      self.klass.constantize.all
    else
      self.klass.constantize.all(:conditions => ar_params.reverse.push(ar_conditions).reverse)
    end
    grs = klass.constantize.group_stats_by(self.case_status_key, rs)
    update_attribute :last_run_at, Time.now
    return grs, nil
  end

  def build_float_sql klass, kattr, operator, value
    if %w(< <= = >= >).include?(operator)
      return "#{klass.table_name}.#{kattr} #{operator} ?", value, nil
    else
      return nil, nil, 'invalid operator'
    end
  end

  def build_boolean_sql klass, kattr, operator, value
    if operator == '='
      return "#{klass.table_name}.#{kattr} = ?", true, nil
    else
      return "#{klass.table_name}.#{kattr} != ?", true, nil
    end
  end

  def build_enumeration_sql klass, kattr, operator, values
    k = klass.const_get(kattr.pluralize.upcase)
    "#{klass.table_name}.#{kattr} IN (#{values.split(' ').map { |v| k.index(v) }.join(',')})"
  end

  def build_string_sql klass, kattr, operator, values
    return "#{klass.table_name}.#{kattr} IN (?)", values.split(' '), nil
  end

  def build_integer_sql klass, kattr, operator, value
    if klass.constants.include?(kattr.pluralize.upcase)
      return build_enumeration_sql(klass, kattr, operator, value)
    else
      if %w(< <= = >= >).include?(operator)
        return "#{klass.table_name}.#{kattr} #{operator} ?", value, nil
      else
        return nil, nil, 'invalid operator'
      end
    end
  end

  def build_age_sql klass, kattr, operator, value
    age = value.to_i
    case operator
    when '<', '<=', '>=', '>'
      return "? #{operator} #{klass.table_name}.#{kattr}", age.months.ago, nil
    when '='
      return "#{klass.table_name}.#{kattr} >= ? AND #{klass.table_name}.#{kattr} < ?", [age.years.ago, (age+1).years.ago - 1.day], nil
    else
      return nil, nil, 'invalid operator'
    end
  end

  def self.latest_run limit=4
    all(:order => 'last_run_at DESC', :limit => limit, :conditions => ['last_run_at IS NOT NULL'])
  end
end
