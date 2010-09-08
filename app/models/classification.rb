class Classification < ActiveRecord::Base
  belongs_to :illness
  has_and_belongs_to_many :diagnostics
  has_and_belongs_to_many :signs
  
  LEVELS = [:low, :medium, :high]

  def self.run diag
    data = diag.to_hash
    all.each { |i| i.run diag, data }
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
    Csps::Formula.new(equation).calculate(data)
  end
  
end
