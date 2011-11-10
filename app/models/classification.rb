class Classification < ActiveRecord::Base
  enum :age_group, Csps::Age::GROUPS

  belongs_to :illness
  has_many :treatments
  has_and_belongs_to_many :diagnostics
  has_and_belongs_to_many :signs
  validates_presence_of :equation

  scope :for_child, ->(obj) { where(age_group: obj.age_group) }
  
  LEVELS = [:low, :medium, :high]

  def self.run diag
    data = diag.to_hash
    for_child(diag).each { |i| i.run diag, data }
  end

  def run diag, data={}
    if calculate(data || diag.to_hash)
      diag.classifications << self unless diag.classifications.include?(self)
    else
      diag.classifications.delete self
    end
    if diag.failed_classifications.present?
      diag.failed_classifications -= [id]
      diag.save if diag.changed?
    end
  rescue => e
    diag.classifications.delete self
    diag.update_attribute :failed_classifications, [*diag.failed_classifications].uniq
  end

  def calculate data
    puts "CALCULATING: #{data}"
    if equation.present?
      Csps::Formula.new(equation).calculate(data)
    else
      false
    end
  end
end
