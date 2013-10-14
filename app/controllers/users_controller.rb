class UsersController < ApplicationController
  admin_required except: [:create, :password, :update]
  login_required only: [:password, :update], expire: false

  before_filter :admin_or_first_run, only: :create
  before_filter :paged, only: [ :logins, :user_logins ]

  fetch 'User', also: [ :user_logins ]

  layout :decide_layout

  def index
    back 'Rechercher un patient', children_path
    @users = User.order('admin DESC, name ASC')
    @logins = Event.logins.history.joins(:user).limit(10)
  end

  def new
    back 'Retour', users_path
    @user = User.new
  end

  def create
    restore = User.count.zero? && params[:restore].present?
    @user = User.new params[:user]
    if Csps.site.blank?
      if params[:zone_id] and zone = Zone.find(params[:zone_id])
        zone.occupy! restore
      else
        @user.errors[:base] << :no_site
      end
    end
    if User.count.zero?
      @user.admin = true
    elsif @user.admin
      @user.password_expired_at = Time.now
    end

    return see_other('/session/restore') if restore

    if @user.save
      if !logged_in? && @user.admin
        persist_user_into_session @user
        see_other children_path
      else
        see_other users_path
      end
    elsif Csps.site
      render action: 'new'
    else
      render template: 'session/welcome'
    end
  end

  def edit
    back 'Retour', users_path
  end

  def update
    data = params[:user]
    if @user == current_user && @user.password_expired?
      puts "first"
      data = data.keep %w(password password_confirmation)
      data[:password_expired_at] = nil
      act = 'password'
      ret = nil
    elsif @user.password_expired?
      puts 'second'
      return see_other('/user/password')
    elsif admin?
      puts 'third'
      act = 'edit'
      ret = users_path
    else
      puts 'fourth'
      return denied
    end

    if @user.update_attributes data
      see_other(ret || session.delete(:after_change) || '/')
    else
      render action: act
    end
  end

  def destroy
    if @user != current_user && @user.diagnostics.empty?
      @user.destroy
    end
    see_other users_path
  end

  def logins
    @logins = Event.logins.history.joins(:user)
  end

  def user_logins
    @logins = @user.events.logins.history
  end

  def password
  end

  protected

  def paged
    @page = (params[:page] || '1').to_i
  end

  def logged_in_or_first_run
    User.count.zero? || logged_in? || denied
  end
  
  def admin_or_first_run
    User.count.zero? || (logged_in? and admin?) || denied
  end

  def decide_layout
    logged_in? ? 'application' : 'lobby'
  end
end
