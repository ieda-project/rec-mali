class Csps::Formula
  class FormulaError < StandardError; end
  attr_reader :code, :data

  EQ = %w(== != <= >= < >)
  LOGICAL = {
    'AND' => ' && ',
    'OR'  => ' || ' }
  RE = /([a-z0-9._+]+|EXACTLY_ONE_OF\(|AT_LEAST_TWO_OF\(|AT_MOST_ONE_OF\(|,|#{LOGICAL.keys.join('|')}|[\(\)]|#{EQ.join('|')}|!)/

  def initialize code
    @code = code
  end

  def self.compile illness, equation
    src = equation.scan(RE).map &:first
    was_eq = false
    arr = src.map.with_index do |token,i|
      if was_eq 
        was_eq = false
        (token =~ /[a-z]/ ?  "'#{token}'" : token) + ')'
      elsif EQ.include? token
        was_eq = true
        " #{token} "
      elsif LOGICAL[token]
        LOGICAL[token]
      elsif token == ','
        ', '
      elsif token =~ /\A[a-z_.]+\Z/
        token = "#{illness.key}.#{token}" unless token.index(?.)
        if EQ.include?(src[i+1])
          "(data['#{token}'] && data['#{token}']"
        else
          "data['#{token}']"
        end
      else
        token
      end
    end
    arr.join ''
  end

  def calculate data
    @data = data
    eval(@code)
  rescue SyntaxError
    raise FormulaError, 'Syntax error in formula'
  rescue ArgumentError
    raise FormulaError, 'Argument error in formula'
  ensure
    @data = nil
  end

  def AT_LEAST_TWO_OF *args
    args.inject 0 do |c,i|
      return true if i && (c += 1) == 2 # 2 is OK, so it ends iteration
      c
    end
    false
  end

  def AT_MOST_ONE_OF *args
    args.inject 0 do |c,i|
      return false if i && (c += 1) == 2 # 2 is TOO MUCH, so it ends iteration
      c
    end
    true
  end

  def EXACTLY_ONE_OF *args
    args.inject 0 do |c,i|
      return false if i && (c += 1) > 1
      c
    end
    c == 1
  end
end
