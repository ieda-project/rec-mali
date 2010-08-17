require 'json'

class QueriesController < ApplicationController
  login_required
  fetch 'Query'
  helper Ziya::HtmlHelpers::Charts

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
        chart = Ziya::Charts::Column.new
        chart.add :theme, 'pimp'
        labels = @results.keys.sort
        labels = labels.map { |k| k[-2..-1] == '01' ? k[0..3] : '' } if labels.size > 12
        chart.add :axis_category_text, labels
        chart.add :series, '', @results.keys.sort.map { |k| @results[k] }
        render xml: chart.to_xml
      end
    end
  end

  def export
    @query = Query.find(params[:id])
    @results, errors = @query.run
    report = StringIO.new
    workbook = Spreadsheet::Excel.new(report)
    worksheet = workbook.add_worksheet(_(@query.title))
    worksheet.write(0, 0, _(@query.title))
    @results.keys.sort.reverse.each_with_index do |k, i|
      worksheet.write(i+1, 0, k)
      worksheet.write(i+1, 1, @results[k])
    end
    workbook.close
    send_data report.string, :filename => 'report_query_'+params[:id]+'_.xls', :content_type => "application/xls" 
  end
end
