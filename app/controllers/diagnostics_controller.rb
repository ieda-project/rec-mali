class DiagnosticsController < ApplicationController
  before_filter :fetch_child

  def show
    back 'Toutes les consultations', @child
    @diagnostic = @child.diagnostics.find params[:id]
  rescue
    not_found
  end

  def new
    @diagnostic = @child.diagnostics.new.prebuild
  end

  def create
    answers = params[:diagnostic].delete(:sign_answers).values
    @diagnostic = @child.diagnostics.new params[:diagnostic]
    @diagnostic.author = current_user
    answers.each { |a| @diagnostic.sign_answers.add(a) }

    if @diagnostic.save
      see_other [@child, @diagnostic]
    else
      unprocessable action: :new
    end
  end

  def edit
    @diagnostic = @child.diagnostics.find params[:id]
  rescue
    not_found
  end

  def update
    @diagnostic = @child.diagnostics.find params[:id]
    Diagnostic.transaction do
      params[:diagnostic].delete(:sign_answers).each_value do |a|
        @diagnostic.sign_answers.add(a)
      end
      if @diagnostic.update_attributes params[:diagnostic]
        see_other [@child, @diagnostic]
      else
        unprocessable action: :new
      end
    end
  end

  protected

  def fetch_child
    @child = Child.find(params[:child_id]) or not_found
  end
end
