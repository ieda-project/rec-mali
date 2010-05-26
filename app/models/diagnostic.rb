class Diagnostic < ActiveRecord::Base
  include Csps::Exportable
  belongs_to :child
  belongs_to :author, class_name: 'User'
  has_many :illness_answers
  has_many :sign_answers do
    def for illness
      select { |a| a.sign.illness == illness }
    end
  end
  has_many :classifications
  before_create :set_date
  after_create :update_child

  validates_presence_of :child

  protected

  def update_child
    child.update_attribute :last_visit_at, created_at
  end

  def set_date
    self.done_on ||= Date.today
  end
end
