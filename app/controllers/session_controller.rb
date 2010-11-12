# encoding: utf-8

class SessionController < ApplicationController
  def create
    data = params[:session]
    @to = params[:to] || request.env['HTTP_REFERER'] || '/'
    @user_id = data[:user_id]

    if data.respond_to?(:[]) && user = User.authenticate(@user_id, data[:password])
      persist_user_into_session user
      see_other @to
    else
      @error = 'Identifiant ou mot de passe invalide!'
      render template: 'shared/401', layout: 'lobby'
    end
  end

  def destroy
    remove_user_from_session
    see_other '/'
  end

  def welcome
    @user = User.new
    render layout: 'lobby'
  end

  def restore
    render layout: 'lobby'
  end
end
