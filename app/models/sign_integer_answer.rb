class SignIntegerAnswer < SignAnswer
  #validates_presence_of :integer_value

  def value
    if integer_value.nil?
      'Not applicable'
    else
      integer_value
    end
  end

  def raw_value
    integer_value
  end
  
  def self.cast v
    v.to_i
  end
end
