class Sign < ActiveRecord::Base
  belongs_to :illness
  has_and_belongs_to_many :classifications
  has_many :answers, class_name: 'SignAnswer'

  def full_key
    "#{illness.key}.#{key}"
  end

  def build_answer data={}
    answer_class.new data.merge(sign: self)
  end
end
