module ApplicationHelper
  def partial name, opts={}
    render opts.merge(partial: name)
  end

  def search_form &block
    form_for :q, html: { method: 'get' }, &block
  end
end
