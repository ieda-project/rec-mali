class IntegerSign < Sign
  def kind
    'integer'
  end

  def html_attributes
    super.tap do |h|
      h[:size] = max_value ? max_value.to_s.length+1 : 3
      h["data-min"] = min_value if min_value
      h["data-max"] = max_value if max_value
    end
  end

  def answer_class
    SignIntegerAnswer
  end
end
