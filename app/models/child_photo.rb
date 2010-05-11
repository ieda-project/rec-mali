class ChildPhoto < ActiveRecord::Base
  include Csps::Exportable
  belongs_to :child
end
