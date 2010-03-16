class Diagnostic < ActiveRecord::Base
  belongs_to :child
  belongs_to :author
end
