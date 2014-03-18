# encoding: utf-8

module ChildrenHelper
  def village ch
    if ch.village
      ch.village.name
    elsif ch.village_name.present?
      "#{ch.village_name} (hors zone)"
    else
      '-'
    end
  end

  def zone_select_for_child ch
    Zone.csps.to_select.tap do |out|
      out << [
        "#{ch.village_name} (hors zone)",
        nil,
        { 'data-village' => ch.village_name, selected: true }] if ch.village_name.present?
      out << ['Hors zone', nil]
    end
  end

  def example_identifier
    if ch = Child.first
      ch.identifier
    else
      "ABCD-EFGH-JK"
    end
  end

  def form_gender val
    case val
    when true then '1'
    when false then '0'
    else ''
    end
  end

  def nee gender
    case gender
    when true then "Née"
    when false then "Né"
    else "Né/e"
    end
  end
end
