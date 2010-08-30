module DiagnosticsHelper
  def selected_boolean form
    case form.object.boolean_value
      when false then 0
      when true then 1
    end
  end

  def index_value diagnostic, name
    if @values
      @values[name]
    elsif diagnostic && !diagnostic.new_record?
      diagnostic.index_ratio(name)
    end
  end

  def index_style name, value, graph=true
    returning [name] do |ret|
      ret << 'has-graph' if graph
      if value.is_a? Float
        if value < Index::WARNING[name]
          ret << 'warning'
        elsif value < Index::ALERT[name]
          ret << 'alert'
        end
      else
        ret << 'disabled'
      end
    end
  end
end
