class Medicine < ActiveRecord::Base
  has_many :prescriptions
  has_many :treatments, through: :prescriptions
end
