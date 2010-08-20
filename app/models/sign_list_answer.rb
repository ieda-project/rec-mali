class SignListAnswer < SignAnswer
  #validates_presence_of :list_value
  validate :validate_list_value

  def value
    if list_value.blank?
      'Non applicable'
    else
      I18n.t "signs.#{list_value}"
    end
  end

  def raw_value
    list_value
  end

  protected

  def validate_list_value
    errors[:list_value] << :inclusion unless list_value.blank? or sign.options.include? list_value
  end
  
  def self.cast v
    v.to_s
  end
end
