class Sign < ActiveRecord::Base
  belongs_to :illness
  has_many :answers, class_name: 'SignAnswer'
end
