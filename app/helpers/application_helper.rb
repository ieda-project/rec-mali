# encoding: utf-8

require 'redcloth'

module ApplicationHelper
  def sortable_header name, label
    a,d = if params[:o] == label
      [' class="current"'].send(
        params[:d] == 'd' ? :unshift : :push,
        '')
    end
    %Q(#{name} <a#{a} href="?o=#{label}">↓</a> <a#{d} href="?o=#{label}&d=d">↑</a>)
  end

  def partial name, opts={}
    render opts.merge(partial: name)
  end

  def search_form &block
    form_for :q, html: { method: 'get', class: 'search' }, &block
  end

  def html textile
    RedCloth.new(textile).to_html
  end

  def months_to_text m
    if m > 60
      years, rem = m.divmod 12
      "#{years}#{rem >= 6 ? '½' : ''} ans"
    else
      "#{m} moins"
    end
  end

  def errors_on form, field
    render :partial => 'shared/errors', :locals => {:form => form, :field => field}
  end
end
