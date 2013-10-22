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

  def index_score diagnostic, name
    if @scores
      @scores[name]
    elsif diagnostic && !diagnostic.new_record?
      diagnostic.z_score(name)
    end
  end

  def index_style name, value, graph=true
    [name].tap do |ret|
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

  def for_selection
    dupes, opts = @diagnostic.dupe_prescriptions, @diagnostic.optional_prescriptions
    lambda do |p,txt|
      checked = @diagnostic.ordonnance.include?(p.id) ? ' checked="checked"' : nil
      if dupes.include?(p)
        %Q(<input type="radio" name="diagnostic[ordonnance][#{p.medicine_id}]" value="#{p.id}"#{checked}><label>#{txt}</label>)
      elsif opts.include?(p)
        %Q(<input type="checkbox" name="diagnostic[ordonnance][#{p.medicine_id}]" value="#{p.id}"#{checked}><label>#{txt}</label>)
      else
        txt
      end
    end
  end

  def for_display
    explicit = @diagnostic.dupe_prescriptions | @diagnostic.optional_prescriptions
    lambda do |p,txt|
      if !explicit.include?(p) || @diagnostic.ordonnance.include?(p.id)
        txt
      end
    end
  end
end
