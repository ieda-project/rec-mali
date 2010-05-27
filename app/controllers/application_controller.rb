class ApplicationController < ActionController::Base
  include Wopata::ActionController::Statuses
  authenticate_from :session
  attr_reader :back_title, :back_url
  helper_method :back_title, :back_url, :back?, :page, :show?

  def show?
    params[:action] == 'show'
  end

  def back title, url
    @back_title, @back_url = title, url
  end

  def back?
    !!@back_url
  end

  def page
    params[:p]
  end

  protected

  class << self
    def fetch model, opts={}
      module_eval "def model; #{model}; end"
      fp = Array(opts.delete(:parents) || opts.delete(:parent) || []).map do |ref|
        "if params[:#{ref}_id]
           @parent = @#{ref} = #{ref.to_s.camelize}.find(params[:#{ref}_id]) rescue return(not_found)
         end"
      end
      if fp.any?
        fp << 'not_found' if opts[:root] == false
        module_eval "
          def fetch_parent
            #{fp.join("\n")}
          end", __FILE__, __LINE__
        module_eval "
          def fetch 
            @object = @#{model.underscore} =
            (@parent ?
             @parent.#{model.underscore.pluralize} :
             #{model}).find(params[:id]) rescue not_found
          end", __FILE__, __LINE__
      else
        module_eval "
          def fetch
            @object = @#{model.underscore} = #{model}.find(params[:id]) rescue not_found
          end", __FILE__, __LINE__
      end

      opts[:only] = [ :show, :edit, :update, :destroy, *(opts[:also] || []) ] unless opts[:only] || opts[:except]
      prepend_before_filter :fetch, opts
      prepend_before_filter :fetch_parent if fp.any?
    end
  end

  def login_required
    logged_in? || denied
  end

  [ :login_required ].each do |filter|
    class_eval "def self.#{filter} *args; before_filter :#{filter}, *args; end", __FILE__, __LINE__
  end
end
