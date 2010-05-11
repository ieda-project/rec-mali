class Diagnostic < ActiveRecord::Base
  include Csps::Exportable
  belongs_to :child
  belongs_to :author
  has_many :illness_answers
  has_many :sign_answers
  has_many :classifications
end
