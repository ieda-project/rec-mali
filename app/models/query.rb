require 'json'

class Query < ActiveRecord::Base
  # These correspond to diag kinds "first", "initial" and "follow" in this order.
  enum :case_status, %w{first initial follow new old}
  CASE_STATUSES.each.with_index { |n,i| const_set n.upcase, i }

  AGE = {
    'SQLite' => ->(ref, age) { "date(#{ref}, '-#{age} months')" },
    'PostgreSQL' => ->(ref, age) { "(#{ref} - interval '#{age} months')" }}
  DAYS = {
    'SQLite' => ->(ref, age) { "date(#{ref}, '-#{age} days')" },
    'PostgreSQL' => ->(ref, age) { "(#{ref} - interval '#{age} days')" }}

  validates_presence_of :title, :klass

  def run
    k, ca = klass.constantize, connection.adapter_name
    aref = k.age_reference_field
    rel = case_status ? k.where(kind: case_status) : k

    rel = case case_status
      when NEW              then k.where('kind IN (?)', [FIRST, INITIAL])
      when OLD              then k.where('kind IN (?)', [INITIAL, FOLLOW])
      when FIRST..FOLLOW    then k.where(kind: case_status)
      else k
    end

    for cond in Array(YAML.load(conditions))
      rel = case cond['type']
        when 'age'
          rel.where "#{AGE[ca].(aref, cond['value'].to_i)} #{cond['operator']} #{k.table_name}.born_on"
        when 'days'
          rel.where "#{DAYS[ca].(aref, cond['value'].to_i)} #{cond['operator']} #{k.table_name}.born_on"
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

    results = rel.group(:month).count(distinct && "DISTINCT #{distinct}").tap do |h|
      h.keys.each do |k|
        s = k.to_s
        h.store "#{s[0,4]}/#{s[4,2]}", h.delete(k)
      end
    end
    fill_in_gaps results
  ensure
    update_attribute :last_run_at, Time.now
  end

  def self.latest_run limit=4
    all(:order => 'last_run_at DESC', :limit => limit, :conditions => ['last_run_at IS NOT NULL'])
  end

  protected

  def fill_in_gaps data
    return data if data.blank?

    ks = data.keys.sort
    time = Time.parse ks.first
    finish = Time.parse ks.last
    while time < finish do
      key = time.strftime('%Y/%m')
      data[key] ||= 0
      time += 1.month
    end
    data
  end

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
