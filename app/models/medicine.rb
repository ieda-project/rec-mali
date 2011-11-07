class Medicine < ActiveRecord::Base
  UNITS_VARS = {
    'k' => 'weight', 'kg' => 'weight',
    'y' => 'age', 'm' => 'months' }

  has_many :prescriptions
  has_many :treatments, through: :prescriptions
  serialize :formula

  validate do
    if formula_changed?
      begin
        self.code = generate_formula_code
      rescue => e
        puts formula.inspect
        errors[:formula] << :invalid
      end
    end
  end

  protected

  def generate_formula_code
    buf = []
    units = UNITS_VARS.keys.join('|')
    num = ->(n) do
      f = n.to_f
      f.to_i == f ? n.to_i : f
    end
    ruby = formula.map do |conds|
      f = case (f = conds.pop)
        when /^[0-9.]+$/ then num.(f)
        when /^([0-9]+)\/([0-9]+)$/ then "Rational(#{$1}, #{$2})"
        when /^([0-9.]+)\/(#{units})$/ then "#{UNITS_VARS[$2]} * #{num.(f)}"
        else raise 'Illegal formula'
      end

      if conds.any?
        conds = conds.map do |src|
          case src
            when /^([\[\]])([0-9.]+)[-;]([0-9]+)(#{units})([\[\]])$/
              # 1: [], 2: min, 3: max, 4: unit, 5: []
              var = UNITS_VARS[$4]
              [ num.($2), ($1 == '[' ? '<=' : '<'), var, '&&',
                var, ($5 == ']' ? '<=' : '<'), num.($3) ]
            when /^(<|>|<=|>=)([0-9.]+)(#{units})$/
              # 1: <>=, 2: value, 3: unit
              [ UNITS_VARS[$3], $1, num.($2) ]
            else
              raise 'Illegal condition'
          end.join(' ')
        end
        "return #{f} if #{conds.join(' && ')}"
      else
        "return #{f}"
      end
    end.join("\n")
  end
end
