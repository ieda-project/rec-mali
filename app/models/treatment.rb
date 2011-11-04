class Treatment < ActiveRecord::Base
  belongs_to :classification
  has_many :prescriptions
  has_many :medicines, through: :prescriptions
end
