class SignListAnswer < SignAnswer
  validate :validate_list_value
  before_save :handle_na

  def value
    applicable? ? I18n.t("signs.#{list_value}") : 'n/a'
  end

  def raw_value
    list_value
  end

  def applicable?
    list_value.present?
  end

  protected

  def validate_list_value
    errors[:list_value] << :inclusion unless list_value.blank? || sign.options.include?(list_value)
  end

  def handle_na
    self.list_value = nil if list_value.blank?
  end
  
  def self.cast v
    v.to_s
  end
end
