class Sign < ActiveRecord::Base
  enum :age_group, %w(newborn infant child)

  belongs_to :illness
  has_and_belongs_to_many :classifications
  has_many :answers, class_name: 'SignAnswer'

  def full_key
    "#{illness.key}.#{key}"
  end

  def build_answer data={}
    answer_class.new data.merge(sign: self)
  end

  def html_attributes
    returning('data-key' => key, 'class' => kind) do |h|
      h['data-dep'] = dep if dep.present?
    end
  end
end
