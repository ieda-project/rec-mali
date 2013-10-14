# encoding: utf-8

class SessionController < ApplicationController
  def create
    data = params[:session]
    @to = params[:to] || request.env['HTTP_REFERER'] || '/'
    @user_id = data[:user_id]

    if data.respond_to?(:[]) && user = User.authenticate(@user_id, data[:password])
      user.events.create kind_key: :login
      persist_user_into_session user

      if user.admin
        old = User.where('admin = ? AND created_at < ?', true, user.created_at)
        if old.any?
          # There are admins that had been created before this user.
          # They have to be demoted. Then our new user will need to have their
          # password changed.
          old.update_all admin: false
        end
      end

      see_other @to
    else
      @error = 'Identifiant ou mot de passe invalide!'
      render template: 'shared/401', layout: 'lobby'
    end
  end

  def destroy
    current_user.events.create kind: :logout
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
