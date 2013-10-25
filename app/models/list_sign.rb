class ListSign < Sign
  def kind
    'list'
  end

  def answer_class
    SignListAnswer
  end

  def options
    @options ||= values.split(';')
  end
end
