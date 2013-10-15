require 'bcrypt'

class User < ActiveRecord::Base
  include Csps::Exportable
  attr_reader :password, :password_confirmation

  globally_has_many :diagnostics, as: :author
  has_many :events

  validates_presence_of :name
  validates_presence_of :password, :on => :create
  validates_presence_of :password_confirmation, :if => :password
  validates_confirmation_of :password, :if => :password
  before_save :crypt_password
  
  scope :admins, :conditions => {:admin => true}
  scope :local, ->() { Zone.csps ? where(zone_id: Zone.csps.id) : where(id: 0) }

  def password= pwd; @password = pwd if pwd.present?; end
  def password_confirmation= pwd; @password_confirmation = pwd if pwd.present?; end

  def self.authenticate user_id, password
    if Csps.site
      (u = find_by_id_and_zone_id(user_id, Zone.csps.id)) &&
      u.authenticate(password) &&
      u
    end
  end

  def authenticate password
    BCrypt::Password.new(crypted_password) == password
  end
  
  def self.to_login_select
    select('id, name').map { |u| [ u.id, u.name ] }
  end

  def password_expired?
    password_expired_at && password_expired_at < Time.now
  end

  protected

  def crypt_password
    self.crypted_password = BCrypt::Password.create password if password
  end
end
