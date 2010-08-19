class SignIntegerAnswer < SignAnswer
  validates_presence_of :integer_value

  def value
    integer_value
  end
  alias raw_value value
  
  def self.cast v
    v.to_i
  end
end
