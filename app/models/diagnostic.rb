class Diagnostic < ActiveRecord::Base
  include Csps::Exportable
  belongs_to :child
  belongs_to :author, class_name: 'User'
  has_and_belongs_to_many :classifications do
    def for illness
      select { |c| c.illness_id == illness.id }
    end
  end
  has_many :sign_answers, include: :sign,
           after_add: :clear_classifications, after_remove: :clear_classifications do
    def add data
      sign = data.delete(:sign) || Sign.find(data.delete(:sign_id)) rescue nil
      existing = detect { |i| i.sign_id == sign.id }
      if existing
        existing.attributes = data
        if existing.changed?
          existing.save
          proxy_owner.send :clear_classifications
        end
      else
        returning(sign ? sign.build_answer(data) : SignAnswer.new(data)) { |sa| push sa }
      end
    end
    def for illness
       select { |a| a.sign.illness_id == illness.id }
    end
    def to_hash
      returning({}) do |hash|
        includes(sign: :illness).each do |answer|
          hash.store answer.sign.full_key, answer.value
        end
      end
    end
  end
  has_many :illness_answers

  before_create :set_date
  after_create :update_child

  validates_presence_of :child

  def type_name
    '-'
  end

  def prebuild
    sign_ids = sign_answers.map(&:sign_id).to_hash
    Sign.order(:sequence).each do |i| 
      sign_answers.build(sign: i) unless sign_ids[i.id]
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

  def clear_classifications obj
    classifications.clear
  end
end
