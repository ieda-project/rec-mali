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
end
