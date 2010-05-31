class BooleanSign < Sign
  def kind
    'boolean'
  end

  def answer_class
    SignBooleanAnswer
  end
end
