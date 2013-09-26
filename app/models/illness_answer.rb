class IllnessAnswer < ActiveRecord::Base
  include Csps::Exportable
  belongs_to :illness
  globally_belongs_to :diagnostic
end
