class DiagnosticsController < ApplicationController
  login_required
  before_filter :fetch_child, :except => :indices
  before_filter :fetch, only: [ :show, :wait, :treatments, :calculations, :edit, :update ]
  helper Ziya::HtmlHelpers::Charts
  helper Wopata::Ziya::HtmlHelpersFix

  def show?
    %w(show treatments).include? params[:action]
  end

  def show
    back 'Toutes les consultations', @child
  end

  def wait  
    render layout: 'empty'
  end

  def treatments
    back 'Consultation', [ @child, @diagnostic ]
  end

  def indices
    weight = params[:weight].to_i
    height = params[:height].to_i
    if params[:child_id] == '-1' # New child
      age = ((Date.today - Date.civil(params[:year].to_i, params[:month].to_i, params['day'].to_i)) / 365.0 * 12).to_i
      gender = (params[:gender] == '1')
    else
      child = Child.find(params[:child_id]) if params[:child_id].present?
      age = child.months
      gender = child.gender
    end
    @values = {}
    @values['weight_age'] = (weight / Index.weight_age.gender(gender).near(age).y * 100).round(0) rescue '-'
    @values['height_age'] = (height / Index.height_age.gender(gender).near(age).y * 100).round(0) rescue '-'
    @values['weight_height'] = (weight / Index.weight_height.gender(gender).near(height).y * 100).round(0) rescue '-'
    render :partial => 'indices'
  end

  def calculations
    Classification.run @diagnostic
    respond_to do |wants|
      wants.html { see_other [ @child, @diagnostic ] }
      wants.json do
        data = {}
        @diagnostic.classifications.each do |i|
          (data[i.illness_id] ||= []) << i.name
        end
        render json: data
      end
    end
  end

  def new
    back 'Toutes les consultations', @child
    @diagnostic = @child.diagnostics.new.prebuild
  end

  def create
    answers = params[:diagnostic].delete(:sign_answers).values
    @child.update_attributes params[:diagnostic].delete(:child)
    @diagnostic = @child.diagnostics.new params[:diagnostic]
    @diagnostic.author = current_user
    answers.each { |a| @diagnostic.sign_answers.add(a) }

    if @diagnostic.save
      see_other [:wait, @child, @diagnostic]
    else
      unprocessable action: :new
    end
  end

  def edit
    back 'La consultation', [@child, @diagnostic]
  end

  def update
    Diagnostic.transaction do
      @child.update_attributes params[:diagnostic].delete(:child)
      (params[:diagnostic].delete(:sign_answers) || {}).each_value do |a|
        @diagnostic.sign_answers.add(a)
      end
      final = (params[:step] == 'final')
      if @diagnostic.update_attributes params[:diagnostic]
        if final
          see_other [ @child, @diagnostic ]
        else
          see_other [:wait, @child, @diagnostic]
        end
      else
        unprocessable action: (final ? :treatments : :edit)
      end
    end
  end

  protected

  def fetch_child
    @child = Child.find(params[:child_id]) or not_found
  end

  def fetch
    @diagnostic = @child.diagnostics.find params[:id]
  rescue ActiveRecord::RecordNotFound
    not_found
  end
end
