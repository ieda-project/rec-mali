module Doorman
  module Controller
    module InstanceMethods
      attr_reader :current_user

      def self.included controller
        controller.send :helper_method, :current_user, :logged_in?
        controller.send :prepend_before_filter, :authentication
      end

      def logged_in?
        !!current_user
      end

      protected

      def authentication
        (self.class.authentication_engines || []).find do |engine|
          @current_user = send("authenticate_from_#{engine}")
        end
      end
    end

    module ClassMethods
      def self.extended controller
        controller.send :cattr_reader, :authentication_engines
      end

      def authenticate_from *args
        args.flatten!
        args.each do |engine|
          include InstanceMethods
          include "Doorman::Engines::#{engine.to_s.camelize}".constantize
        end
        class_variable_set :@@authentication_engines,
                           ((authentication_engines || []) + args).uniq
      end
    end
  end
end
