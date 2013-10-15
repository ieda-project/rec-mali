module ChildrenHelper
  def village ch
    if ch.village
      ch.village.name
    elsif ch.village_name.present?
      "#{ch.village_name} (Hors zone)"
    else
      '-'
    end
  end

  def zone_select_for_child ch
    Zone.csps.to_select.tap do |out|
      out << [
        "Hors zone: #{ch.village_name}",
        nil,
        { 'data-village' => ch.village_name, selected: true }] if ch.village_name.present?
      out << ['Hors zone', nil]
    end
  end
end
