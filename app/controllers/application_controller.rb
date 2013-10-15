class ApplicationController < ActionController::Base
  before_filter :prepare_everything

  include Wopata::ActionController::Statuses
  authenticate_from :session
  attr_reader :back_title, :back_url
  helper_method :back_title, :back_url, :back?, :page, :show?, :admin?

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

  def prepare_everything
    Zone.reload_csps
    params.force_encoding Encoding::UTF_8
  end

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
    if logged_in?
      if current_user.password_expired?
        session[:after_change] = request.fullpath
        see_other '/users/password'
      else
        true
      end
    elsif !Zone.csps || User.local.empty?
      see_other welcome_session_path
    else
      denied
    end
  end

  def login_required_no_expire
    if logged_in?
      true
    elsif !Zone.csps || User.local.empty?
      see_other welcome_session_path
    else
      denied
    end
  end

  def admin_required
    ret = login_required
    if ret == true
      admin? or denied
    else
      ret
    end
  end

  def admin_required_no_expire
    ret = login_required_no_expire
    if ret == true
      admin? or denied
    else
      ret
    end
  end

  def admin?
    current_user.admin?
  end

  class << self
    def login_required *args
      opts = args.first
      if opts && opts.delete(:expire) == false
        before_filter :login_required_no_expire, opts
      else
        before_filter :login_required, *args
      end
    end

    def admin_required *args
      opts = args.first
      if opts && opts.delete(:expire) == false
        before_filter :admin_required_no_expire, opts
      else
        before_filter :admin_required, *args
      end
    end
  end
end
