class Illness < ActiveRecord::Base
  has_many :answers, :class => 'IllnessAnswer'
  has_many :classifications
  has_many :signs
end
