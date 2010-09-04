class UsersController < ApplicationController
  login_required only: [ :index, :show ]
  before_filter :logged_in_or_first_run, except: [ :index, :show ]
  before_filter :admin_or_first_run
  fetch 'User'

  layout :decide_layout

  def index
    back 'Rechercher un patient', children_path
    @users = User.order('admin DESC, name ASC')
  end

  def new
    back 'Retour', users_path
    @user = User.new
  end

  def create
    @user = User.new params[:user]
    if Csps.site.blank?
      if params[:zone_id] and zone = Zone.find(params[:zone_id])
        zone.occupy!
      else
        @user.errors[:base] << :no_site
      end
    end
    @user.admin = User.count.zero?
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
    if @user.update_attributes params[:user]
      see_other users_path
    else
      render action: 'edit'
    end
  end

  protected

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
