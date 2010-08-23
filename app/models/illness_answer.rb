class IllnessAnswer < ActiveRecord::Base
  include Csps::Exportable
  globally_belongs_to :illness
  globally_belongs_to :diagnostic
end
