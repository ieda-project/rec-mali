require 'bcrypt'

class User < ActiveRecord::Base
  include Csps::Exportable
  attr_accessor :password, :password_confirmation

  validates_presence_of :name
  validates_presence_of :password, :on => :create
  validates_confirmation_of :password
  before_save :crypt_password
  
  scope :admins, :conditions => {:admin => true}

  def self.authenticate user_id, password
    if Csps.site
      (u = find_by_id_and_zone_id(user_id, Csps.site.id)) &&
      BCrypt::Password.new(u.crypted_password) == password &&
      u
    end
  end
  
  def self.to_login_select
    all(:select => 'id, name').map {|u| [u.id, u.name]}
  end

  protected

  def crypt_password
    self.crypted_password = BCrypt::Password.create password if password
  end
end
