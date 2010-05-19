module Wopata::ActionController::Responder
  def self.included base
    base.send :remove_method, :api_behavior
    base.send :remove_method, :display
  end

  def to_xml
    default_render
  rescue ActionView::MissingTemplate => e
    raise unless resourceful?
    xopts = { :skip_types => true }
    if get?
      if resource.respond_to?(:each) && controller.model
        xopts[:root] = controller.model.underscore.dasherize.pluralize
      end
      display(resource, {}, xopts)
    elsif has_errors?
      display(resource.errors, { :status => :unprocessable_entity }, xopts)
    elsif post? || put?
      display(resource, { :status => :created, :location => resource_location }, xopts)
    elsif delete?
      controller.render({ :status => :no_content, :nothing => true }, xopts)
    else
      head :ok
    end
  end

  def api_behavior error
      raise error unless resourceful?
      if get?
        display resource
      elsif has_errors?
        display resource.errors, :status => :unprocessable_entity
      elsif post? || put?
        display resource, :status => :created, :location => resource_location
      elsif delete?
        controller.render :status => :no_content, :nothing => true
      else
        head :ok
      end
  end

  private

  def display resource, ropts={}, mopts={}
    controller.render ropts.merge(options).merge(
      format =>
        (resource.send("to_#{format}",
          mopts.merge(:for => controller.current_user)) rescue resource))
  end
end
