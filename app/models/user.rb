require 'bcrypt'

class User < ActiveRecord::Base
  attr_accessor :password, :password_confirmation

  validates_presence_of :login, :name, :password
  validates_confirmation_of :password
  before_save :crypt_password

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
