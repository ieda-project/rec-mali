module Doorman::Engines
  module Session
    protected

    def authenticate_from_session
      if session[:current_user_id]
        begin
          User.find session[:current_user_id]
        rescue
          remove_user_from_session
        end
      end
    end

    def persist_user_into_session user
      @current_user = user
      session[:current_user_id] = user.id
    end

    def remove_user_from_session
      session.delete :current_user_id
    end
  end
end
