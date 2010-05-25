class Sign < ActiveRecord::Base
  belongs_to :illness
  has_many :answers, class_name: 'SignAnswer'

  def kind
    self.class.name.sub(/Sign\Z/, '').underscore
  end
end
