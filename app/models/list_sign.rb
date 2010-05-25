class ListSign < Sign
  def options
    values.split(';')
  end
end
