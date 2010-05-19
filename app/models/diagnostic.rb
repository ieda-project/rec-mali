class Diagnostic < ActiveRecord::Base
  include Csps::Exportable
  belongs_to :child
  belongs_to :author
  has_many :illness_answers
  has_many :sign_answers
  has_many :classifications
  after_create :update_child

  validates_presence_of :child

  protected

  def update_child
    child.update_attribute :last_visit_at, created_at
  end
end
