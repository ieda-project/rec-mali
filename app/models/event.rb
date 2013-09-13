class Event < ActiveRecord::Base
  enum :kind, %w(login logout)
  belongs_to :user

  KINDS.each.with_index do |k,i|
    scope k.pluralize, where(kind: i)
  end
  scope :history, order('created_at DESC')
end
