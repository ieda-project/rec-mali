class IntegerSign < Sign
  def kind
    'integer'
  end

  def html_attributes
    super.merge(size: max_value ? max_value.to_s.length+1 : 3)
  end

  def answer_class
    SignIntegerAnswer
  end
end
