class Illness < ActiveRecord::Base
  has_many :answers, class_name: 'IllnessAnswer'
  has_many :classifications
  has_many :signs
end
