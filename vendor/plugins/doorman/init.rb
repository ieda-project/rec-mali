ActionController::Base.send :include, Doorman::Controller::InstanceMethods
ActionController::Base.send :extend,  Doorman::Controller::ClassMethods
