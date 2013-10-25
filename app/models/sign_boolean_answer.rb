class SignBooleanAnswer < SignAnswer
  def value
    case boolean_value
      when true then 'oui'
      when false then 'non'
      when nil then 'n/a'
    end
  end
  def self.field
    :boolean_value
  end

  def spss_value
    case boolean_value
      when true then 1
      when false then 0
      when nil then ''
    end
  end

  def html_value
    if boolean_value.nil?
      'Non applicable'
    else
      kl = boolean_value ? 'yes' : 'no'
      kl += ' negative' if sign.negative?
      %Q(<div class="switch #{kl}"><div class="yes">Oui</div><div class="no">Non</div></div>)
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
