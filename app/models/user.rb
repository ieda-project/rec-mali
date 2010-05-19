class User < ActiveRecord::Base
  include Csps::Human

  def self.authenticate login, password
    find_by_login login
  end
end
