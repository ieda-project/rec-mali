require 'bcrypt'

class User < ActiveRecord::Base
  include Csps::Exportable
  attr_accessor :password, :password_confirmation

  validates_presence_of :login, :name
  validates_uniqueness_of :login
  validates_presence_of :password, :on => :create
  validates_confirmation_of :password
  before_save :crypt_password
  
  scope :admins, :conditions => {:admin => true}

  def self.authenticate login, password
    (u = find_by_login(login)) &&
    BCrypt::Password.new(u.crypted_password) == password &&
    u
  end

  protected

  def crypt_password
    self.crypted_password = BCrypt::Password.create password if password
  end
end
