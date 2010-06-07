class SignIntegerAnswer < SignAnswer
  validates_presence_of :integer_value

  def value
    integer_value
  end
end
