class SignAnswer < ActiveRecord::Base
  include Csps::Exportable
  belongs_to :sign
  belongs_to :diagnostic
end
