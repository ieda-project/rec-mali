require 'json'

class QueriesController < ApplicationController
  login_required
  fetch 'Query'
  helper Ziya::HtmlHelpers::Charts
  helper Wopata::Ziya::HtmlHelpersFix

  require "spreadsheet/excel" 
  
  def index
    back 'Rechercher un patient', children_path
  end

  def show
    back 'Afficher une autre statistique', queries_path
    @query = Query.find(params[:id])
    @results, errors = @query.run
    respond_to do |format|
      format.html
      format.xml do
        if @results.any?
          chart = Ziya::Charts::Column.new
          chart.add :theme, 'pimp'
          labels = @results.keys.sort
          labels = labels.map { |k| k[-2..-1] == '01' ? k[0..3] : '' } if labels.size > 12
          chart.add :axis_category_text, labels
          chart.add :series, '', @results.keys.sort.map { |k| @results[k] }
          render xml: chart.to_xml
        else
          render nothing: true
        end
      end
    end
  end
end
