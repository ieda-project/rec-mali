class DiagnosticsController < ApplicationController
  before_filter :fetch_child

  def new
    @diagnostic = @child.diagnostics.new
    Sign.order(:sequence).each do |i| 
      @diagnostic.sign_answers.build sign: i
    end
  end

  def create
    answers = params[:diagnostic].delete(:sign_answers).values
    @diagnostic = @child.diagnostics.new params[:diagnostic]
    @diagnostic.author = current_user
    answers.each { |a| @diagnostic.sign_answers.build(a) }

    if @diagnostic.save
      redirect_to @child
    else
      render action: :new
    end
  end

  def edit
  end

  def update
  end

  protected

  def fetch_child
    @child = Child.find(params[:child_id]) or not_found
  end
end
