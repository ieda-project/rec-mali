class Sign < ActiveRecord::Base
  belongs_to :illness
  has_many :answers, :class => 'SignAnswer'
end
