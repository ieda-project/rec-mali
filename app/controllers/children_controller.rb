class ChildrenController < ApplicationController
  login_required
  fetch 'Child'

  Search = Struct.new(:name, :born_on, :village_id)

  def index
    # Clean empty children (only photo)
    Child.unfilled.destroy_all
    @q = Search.from_hash params[:q]
    @children = model.search(@q, params[:o], params[:d])
    @page = (params[:page] || '1').to_i
  end

  def show
    back 'Rechercher un autre patient', children_path
  end

  def new
    @child = Child.new
    @diagnostic = @child.diagnostics.build.prebuild
    back 'Rechercher un autre patient', children_path
  end

  def create
    diag = params[:child].delete(:diagnostic)
    answers = diag.delete(:sign_answers).values

    @child = Child.temporary.first || Child.new
    @child.attributes = params[:child]
    @child.temporary = false

    @diagnostic = @child.diagnostics.build diag
    @diagnostic.child = @child
    @diagnostic.author = current_user
    answers.each { |a| @diagnostic.sign_answers.add(a) }

    if @child.save
      see_other [:wait, @child, @diagnostic]
    else
      render action: 'new'
    end
  end

  def temp
    Child.temporary.destroy_all
    @child = Child.new params[:child].merge(temporary: true)
    display_updated @child.save
  end

  def edit
    if request.xhr?
      render partial: 'edit' if request.xhr?
    else
      render action: 'show'
    end
  end

  def update
    display_updated @child.update_attributes(params[:child])
  end

  protected

  def display_updated success
    respond_to do |wants|
      wants.html do
        success ? redirect_to(:back) : render(action: :show)
      end
      wants.json do
        if success
          render json: { photo: { thumbnail: @child.photo.url(:thumbnail) }}
        else
          render nothing: true, status: 422
        end
      end
    end
  end
end
