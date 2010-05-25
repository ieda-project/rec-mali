class DiagnosticsController < ApplicationController
  before_filter :fetch_child

  def new
    @diagnostic = @child.diagnostics.new
  end

  def create
    @diagnostic = @child.diagnostics.new params[:diagnostic]
    if @diagnostic.save
    else
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
