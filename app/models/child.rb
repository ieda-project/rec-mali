class Child < ActiveRecord::Base
  include Csps::Exportable
  has_many :child_photos
  has_many :diagnostics
end
