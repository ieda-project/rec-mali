class SignBooleanAnswer < SignAnswer
  validates_inclusion_of :boolean_value, in: [ true, false ]

  def value
    boolean_value
  end
end
