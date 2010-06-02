class Csps::Formula
  attr_reader :code, :data

  EQ = %w(== != <= >=)
  LOGICAL = {
    'AND' => ' && ',
    'OR'  => ' || ' }
  RE = /([a-z0-9._]+|TWO_OF\(|,|#{LOGICAL.keys.join('|')}|[\(\)]|#{EQ.join('|')}|!)/

  def initialize cl
    src = cl.equation.scan(RE).map &:first
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
        token = "#{cl.illness.key}.#{token}" unless token.index(?.)
        if EQ.include?(src[i+1])
          "(data['#{token}'] && data['#{token}']"
        else
          "data['#{token}']"
        end
      else
        token
      end
    end
    @code = arr.join ''
  end

  def calculate data
    @data = data
    eval(@code)
  ensure
    @data = nil
  end

  def TWO_OF *args
    args.inject 0 do |c,i|
      return true if i && (c += 1) == 2
      c
    end
    false
  end
end