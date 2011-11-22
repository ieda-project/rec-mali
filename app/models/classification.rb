class Classification < ActiveRecord::Base
  enum :age_group, Csps::Age::GROUPS

  belongs_to :illness
  has_many :treatments
  has_and_belongs_to_many :signs

  has_many :results
  has_many :diagnostics, through: :results

  validates_presence_of :equation
  scope :for_child, ->(obj) { where(age_group: obj.age_group) }
  
  LEVELS = [:low, :medium, :high]

  def self.run diag
    data = diag.to_hash
    for_child(diag).each { |i| i.run diag, data }
  end

  def run diag, data={}
    if calculate(data || diag.to_hash)
      results.create!(diagnostic: diag) unless diag.classifications.include?(self)
    else
      diag.results.where(classification_id: id).destroy_all
    end
    diag.instance_eval { @classifications = nil } # Hack to clear has_many through cache

    if diag.failed_classifications.present?
      diag.failed_classifications -= [id]
      diag.save if diag.changed?
    end
  rescue => e
    diag.results.where(classification_id: self).destroy_all
    diag.update_attribute :failed_classifications, [*diag.failed_classifications].uniq
  end

  def calculate data
    if equation.present?
      Csps::Formula.new(equation).calculate(data)
    else
      false
    end
  end
end
