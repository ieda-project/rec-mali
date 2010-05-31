class Diagnostic < ActiveRecord::Base
  include Csps::Exportable
  belongs_to :child
  belongs_to :author, class_name: 'User'
  has_and_belongs_to_many :classifications
  has_many :illness_answers
  has_many :sign_answers do
    def build data
      sign = data.delete(:sign) || Sign.find(data.delete(:sign_id))
      push(sign ? sign.build_answer(data) : SignAnswer.new(data))
    end
    def for illness
      select { |a| a.sign.illness == illness }
    end
    def to_hash
      returning({}) do |hash|
        includes(sign: :illness).each do |answer|
          hash.store answer.sign.full_key, answer.value
        end
      end
    end
  end
  has_many :classifications
  before_create :set_date
  after_create :update_child

  validates_presence_of :child

  def type_name
    '-'
  end

  def prebuild
    if new_record?
      sign_answers.clear
      Sign.order(:sequence).each do |i| 
        sign_answers.build sign: i
      end
    end
    self
  end

  protected

  def update_child
    child.update_attribute :last_visit_at, created_at
  end

  def set_date
    self.done_on ||= Date.today
  end
end
