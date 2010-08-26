class IllnessesController < ApplicationController
  login_required

  def classification
    illness = Illness.find params[:id]
    if params[:d].present?
      params[:d].each do |k,v|
        params[:d][k] = case v
          when 'true' then true
          when 'false' then false
          when /\A[0-9.]+\Z/ then v.to_f
          when /\A[0-9]+\Z/ then v.to_i
          else v
        end
      end
      puts "USING:"
      puts params[:d].inspect
      ret = illness.classifications.map do |cl|
        puts cl.equation
        [ cl.name, (cl.calculate(params[:d]) rescue 'error') ]
      end
      puts
      puts
      render text: ret.to_json
    else
      render json: {}
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end
end
