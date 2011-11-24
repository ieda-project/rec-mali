class BooleanSign < Sign
  def kind
    'boolean'
  end

  def answer_class
    SignBooleanAnswer
  end

  def html_attributes
    if negative
      super.merge :class => 'boolean negative'
    else
      super
    end
  end
end
