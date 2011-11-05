class Prescription < ActiveRecord::Base
  belongs_to :medicine
  belongs_to :treatment
end
