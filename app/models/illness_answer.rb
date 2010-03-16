class IllnessAnswer < ActiveRecord::Base
  belongs_to :illness
  belongs_to :diagnostic
end
