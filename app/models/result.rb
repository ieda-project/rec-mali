class Result < ActiveRecord::Base
  include Csps::Exportable
  globally_belongs_to :diagnostic
  belongs_to :classification
end
