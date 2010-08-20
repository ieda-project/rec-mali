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

  def textual_age d, ref=nil
    ref ||= Date.today
    months = ((ref - d).to_f / 365.25 * 12).round
    "#{months} mois"
  end

  def age_in_years d, ref=nil
    ref ||= Date.today
    ((ref - d).to_f / 365.25).truncate
  end
  
  def errors_on form, field
    render :partial => 'shared/errors', :locals => {:form => form, :field => field}
  end
end
