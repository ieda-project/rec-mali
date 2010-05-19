class Village < ActiveRecord::Base
  has_many :children
end
