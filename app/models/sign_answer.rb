class SignAnswer < ActiveRecord::Base
  include Csps::Exportable
  belongs_to :sign
  globally_belongs_to :diagnostic

  validates_presence_of :sign, :type
  
  def <=> other
    sign_id <=> other.sign_id
  end
end
