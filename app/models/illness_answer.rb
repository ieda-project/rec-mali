class IllnessAnswer < ActiveRecord::Base
  include Csps::Exportable
  belongs_to :illness
  belongs_to :diagnostic
end
