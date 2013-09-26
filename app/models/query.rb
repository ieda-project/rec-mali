require 'json'

class Query < ActiveRecord::Base
  # These correspond to diag kinds "first", "initial" and "follow" in this order.
  enum :case_status, %w{new old follow}

  AGE = {
    'SQLite' => ->(ref, age) { "date(#{ref}, '-#{age} months')" },
    'PostgreSQL' => ->(ref, age) { "(#{ref} - interval '#{age} months')" }}

  validates_presence_of :title, :klass

  def run
    k, ca = klass.constantize, connection.adapter_name
    aref = k.age_reference_field
    rel = case_status ? k.where(kind: case_status) : k

    for cond in Array(JSON.parse(conditions))
      rel = case cond['type']
        when 'age'
          rel.where "#{AGE[ca].(aref, cond['value'].to_i)} #{cond['operator']} #{k.table_name}.born_on"
        when 'field', 'boolean'
          att, val = k.rewrite_query_conditions cond
          op = (cond['type'] == 'boolean') ? '=' : cond['operator']

          path = att.split '.'
          inkl, model, field = nil, k, path.pop
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
            "uqid IN (
              SELECT diagnostic_uqid FROM sign_answers
              WHERE sign_id=? AND #{sign.answer_class.field} #{cond['operator']} ?)", sign.id, cond['value'])
      end
    end

    rel.group(:month).count('DISTINCT child_uqid')
  ensure
    update_attribute :last_run_at, Time.now
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
