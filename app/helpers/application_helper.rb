# encoding: utf-8

require 'redcloth'

module ApplicationHelper
  def partial name, opts={}
    render opts.merge(partial: name)
  end

  def search_form &block
    form_for :q, html: { method: 'get', class: 'search' }, &block
  end

  def html textile
    RedCloth.new(textile).to_html
  end

  def age d
    months = ((Date.today - d).to_f / 365.25 * 12).round
    if months < 24
      "#{months} mois"
    elsif months < 120
      years, mod = months.divmod 12
      "#{years}#{mod >= 6 && '½'} ans"
    else
      "#{months / 12} ans"
    end
  end
  
  def errors_on form, field
    render :partial => 'shared/errors', :locals => {:form => form, :field => field}
  end
end
