class Classification < ActiveRecord::Base
  belongs_to :illness
  has_and_belongs_to_many :diagnostics
  has_and_belongs_to_many :signs
  has_and_belongs_to_many :treatments

  def self.run diag
    data = diag.sign_answers.to_hash
    all.each { |i| i.run diag, data }
  end

  def run diag, data={}
    if Csps::Formula.new(self).calculate(data || diag.sign_answers.to_hash)
      diag.classifications << self unless diag.classifications.include?(self)
    else
      diag.classifications.delete self
    end
  end
end
