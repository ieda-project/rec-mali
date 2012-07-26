require 'json'

class Query < ActiveRecord::Base
  enum :case_status, %w{new old follow}
  NEW = 0
  OLD = 1
  FOLLOW = 2

  MONTH = {
    'SQLite' => ->(f) { "strftime('%Y-%m', #{f})" },
    'PostgreSQL' => ->(f) { "to_char(#{f}, 'YYYY-MM')" }}
  AGE = {
    'SQLite' => ->(ref, age) { "date(#{ref}, '-#{age} months')" },
    'PostgreSQL' => ->(ref, age) { "(#{ref} - interval '#{age} months')" }}

  validates_presence_of :title, :case_status, :klass

  def run
    k = klass.constantize
    rel, aref = k, k.age_reference_field
    ca = connection.adapter_name

    sub = "(SELECT min(global_id) FROM diagnostics GROUP BY child_global_id)"
    rel = case case_status
      when NEW then rel.where "global_id IN #{sub}"
      when OLD then rel.where "global_id NOT IN #{sub}"
      else rel
    end

    for cond in Array(JSON.parse(conditions))
      rel = case cond['type']
        when 'age'
          rel.where "#{AGE[ca].(aref, cond['value'].to_i)} #{cond['operator']} #{k.table_name}.born_on"
        when 'field', 'boolean'
          path = cond['attribute'].split '.'
          inkl, model, field = nil, k, path.pop

          if cond['type'] == 'boolean'
            val = cond['value'] == 'true'
            op = '='
          else
            val = cond['value']
            op =  cond['operator']
          end

          path.each do |i|
            i = i.intern
            model = model.reflections[i].klass
            inkl = build_include_hash inkl, i
          end

          rel = rel.includes(inkl) if inkl
          rel.where("#{model.table_name}.#{field} #{op} ?", val)
        when 'sign'
          raise "Sign is only supported by Diagnostic" if k != Diagnostic
          sign = Sign.find_by_key cond['sign']
          rel.where(
            "global_id IN (
              SELECT diagnostic_global_id FROM sign_answers
              WHERE sign_id=? AND #{sign.answer_class.field} #{cond['operator']} ?)", sign.id, cond['value'])
      end
    end

    rel.group(MONTH[ca].(aref)).count('DISTINCT child_global_id').tap do
      update_attribute :last_run_at, Time.now
    end
  end

  def self.latest_run limit=4
    all(:order => 'last_run_at DESC', :limit => limit, :conditions => ['last_run_at IS NOT NULL'])
  end

  protected

  def build_include_hash incl, n
    case incl
      when nil then n
      when Symbol then { incl => n }
      when Hash
        key, value = incl.first
        { key => build_include_hash(value, n) }
    end
  end
end
