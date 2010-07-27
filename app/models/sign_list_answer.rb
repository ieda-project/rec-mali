class SignListAnswer < SignAnswer
  validates_presence_of :list_value
  validate :validate_list_value

  def value
    I18n.t "signs.#{list_value}"
  end

  def raw_value
    list_value
  end

  protected

  def validate_list_value
    errors[:list_value] << :inclusion unless sign.options.include? list_value
  end
end
