class DiagnosticsController < ApplicationController
  login_required
  before_filter :fetch_child, :except => :indices
  before_filter :fetch, only: [ :show, :wait, :treatments, :calculations, :edit, :update ]
  before_filter :editable_only, only: [:edit, :update]
  helper Ziya::HtmlHelpers::Charts
  helper Wopata::Ziya::HtmlHelpersFix

  def questionnaire
    #if request.xhr?
      @diagnostic = @child.diagnostics.build_with_answers(born_on: params[:born_on])
      render layout: false
    #else
    #  not_found
    #end
  end

  def show?
    %w(show treatments).include? params[:action]
  end

  def show
    back 'Liste des evaluations', @child
  end

  def wait
    case @diagnostic.state
      when 'opened'
        see_other [:edit, @child, @diagnostic]
      when 'filled'
        render layout: 'empty'
      else
        see_other [:treatments, @child, @diagnostic]
    end
  end

  def treatments
    back "Retour a l'evaluation", [ @child, @diagnostic ]
    case @diagnostic.state
      when 'opened'
        see_other [@child, @diagnostic]
      when 'filled'
        see_other [:wait, @child, @diagnostic]
      when 'calculated' 
        render action: 'select_treatments'
    end
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
    back 'Liste des evaluations', @child
    if @child.of_valid_age?
      @diagnostic = @child.diagnostics.new.prebuild
      @diagnostic.kind_key = params[:kind]
    else
      not_found
    end
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
    back "L'evaluation", [@child, @diagnostic]
  end

  def update
    if @diagnostic.author != current_user && params[:diagnostic].keys != %w(results_attributes)
      return(see_other([ @child, @diagnostic ]))
    end

    Diagnostic.transaction do
      @diagnostic.sign_answers.process params[:diagnostic].delete(:sign_answers)
      @child.update_attributes params[:diagnostic].delete(:child)
      @diagnostic.attributes = params[:diagnostic]
      if @diagnostic.save
        case @diagnostic.state
          when 'filled'
            see_other [ :wait, @child, @diagnostic ]
          when 'calculated'
            @diagnostic.select_treatments
            see_other [ :treatments, @child, @diagnostic ]
          when 'treatments_selected'
            see_other [ :treatments, @child, @diagnostic ]
          when 'closed'
            see_other [ @child, @diagnostic ]
        end
      elsif @diagnostic.calculated? || @diagnostic.treatment_selected?
        treatments || unprocessable(action: :treatments)
      else
        unprocessable action: :edit
      end
    end
  end

  protected

  def fetch_child
    @child = Child.find(params[:child_id]) or not_found
  end

  def fetch
    @diagnostic = @child.diagnostics.find_by_id params[:id]
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def editable_only
    @diagnostic.editable_by? current_user or denied
  end
end
