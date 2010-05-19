ActionController::Responder.send :include, Wopata::ActionController::Responder
ActiveRecord::Base.metaclass.send :alias_method, :[], :find
