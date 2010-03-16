class SignAnswer < ActiveRecord::Base
  belongs_to :sign
  belongs_to :diagnostic
end
