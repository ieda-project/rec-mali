class SignAnswer < ActiveRecord::Base
  include Csps::Exportable
  belongs_to :sign
  belongs_to :diagnostic

  validates_presence_of :sign
end
