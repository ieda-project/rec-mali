class SessionController < ApplicationController
  def create
    data = params[:session]

    if data.respond_to?(:[]) && user = User.authenticate(data[:login], data[:password])
      persist_user_into_session user
    end
    see_other(request.env['HTTP_REFERER'] || '/')
  end

  def destroy
    remove_user_from_session
    see_other '/'
  end
end
