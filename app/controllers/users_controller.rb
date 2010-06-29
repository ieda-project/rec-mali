class UsersController < ApplicationController
  login_required only: [ :index, :show ]
  before_filter :logged_in_or_first_run, except: [ :index, :show ]
  fetch 'User'

  layout :decide_layout

  def index
    @users = User.order :login
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new params[:user]
    if @user.save
      persist_user_into_session @user
      see_other children_path
    else
      render action: 'new'
    end
  end

  def edit
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

  def decide_layout
    logged_in? ? 'application' : 'lobby'
  end
end