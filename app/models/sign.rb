class Sign < ActiveRecord::Base
  enum :age_group, Csps::Age::GROUPS

  belongs_to :illness
  has_and_belongs_to_many :classifications
  has_many :answers, class_name: 'SignAnswer'

  serialize :auto

  def full_key
    "#{illness.key}.#{key}"
  end

  def build_answer data={}
    answer_class.new data.merge(sign: self)
  end

  def html_attributes
    { 'data-key' => key, 'class' => kind }.tap do |h|
      h['data-dep'] = dep if dep.present?
    end
  end

  def auto_js
    "function(data) { " +
    auto.map { |result,code| "if (#{code}) return #{result.inspect};" }.join(' ') +
    " return null }"
  end
end
