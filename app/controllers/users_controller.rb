class UsersController < ApplicationController
  login_required only: [ :index, :show ]
  before_filter :logged_in_or_first_run, except: [ :index, :show ]
  before_filter :admin_or_first_run
  fetch 'User'

  layout :decide_layout

  def index
    back 'Rechercher un patient', children_path
    @users = User.order('admin DESC, login')
  end

  def new
    back 'Retour', users_path
    @user = User.new
  end

  def create
    @user = User.new params[:user]
    @user.admin = true if User.count == 0
    if @user.save
      if User.count == 1
        persist_user_into_session @user
        see_other children_path
      else
        see_other users_path
      end
    else
      render action: 'new'
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
