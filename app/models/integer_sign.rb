class IntegerSign < Sign
  def kind
    'integer'
  end

  def answer_class
    SignIntegerAnswer
  end
end
