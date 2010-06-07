module DiagnosticsHelper
  def selected_boolean form
    case form.object.boolean_value
      when false then 0
      when true then 1
    end
  end
end
