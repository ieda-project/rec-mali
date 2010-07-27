class IllnessesController < ApplicationController
  login_required

  def classification
    illness = Illness.find params[:id]
    if params[:s].present?
      signs = Sign.find(params[:s].keys, include: :illness).to_hash &:id
      data = {}

      params[:s].each do |sign_id,value|
        sign = signs[sign_id.to_i]
        value = (value == '1') if sign.is_a? BooleanSign
        data.store sign.full_key, value
      end

      ret = illness.classifications.map do |cl|
        [ cl.name, (cl.calculate(data) rescue 'error') ]
      end

      render text: ret.to_json
    else
      render json: {}
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end
end
