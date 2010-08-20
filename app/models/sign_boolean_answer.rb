class SignBooleanAnswer < SignAnswer
  #validates_inclusion_of :boolean_value, in: [ true, false ]

  def value
    if boolean_value.nil?
      'Not applicable'
    else
      boolean_value ? 'oui' : 'non'
    end
  end
  
  def html_value
    if boolean_value.nil?
      'Not applicable'
    else
      "<div class='switch #{boolean_value ? 'yes' : 'no'}'><div class='yes'>Oui</div><div class='no'>Non</div></div>"
    end
  end

  def raw_value
    boolean_value
  end
  
  def self.cast v
    %w(t true oui vrai).include? v
  end
end
