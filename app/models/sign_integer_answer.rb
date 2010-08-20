class SignIntegerAnswer < SignAnswer
  def value
    integer_value || 0
  end
  alias raw_value value

  def applicable?
    !!integer_value
  end
  
  def self.cast v
    v.to_i
  end
end
