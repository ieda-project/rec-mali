class SignBooleanAnswer < SignAnswer
  def value
    case boolean_value
      when true then 'oui'
      when false then 'non'
      when nil then 'n/a'
    end
  end
  alias spss_value value

  def html_value
    if boolean_value.nil?
      'Non applicable'
    else
      "<div class='switch #{boolean_value ? 'yes' : 'no'}'><div class='yes'>Oui</div><div class='no'>Non</div></div>"
    end
  end

  def raw_value
    boolean_value
  end

  def applicable?
    boolean_value != nil
  end
  
  def self.cast v
    %w(t true oui vrai).include? v
  end
end
