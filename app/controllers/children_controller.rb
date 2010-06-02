class ChildrenController < ApplicationController
  login_required
  fetch 'Child'

  Search = Struct.new(:first_name, :last_name, :born_on, :village_id)

  def index
    @q = Search.from_hash params[:q]
    @children = model.search(@q)
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
    puts params[:child].inspect
    diag = params[:child].delete(:diagnostic)
    answers = diag.delete(:sign_answers).values
    @child = Child.new params[:child]
    @diagnostic = @child.diagnostics.build diag
    @diagnostic.child = @child
    @diagnostic.author = current_user
    answers.each { |a| @diagnostic.sign_answers.add(a) }

    if @child.save
      see_other @child
    else
      render action: 'new'
    end
  end

  def edit
    if request.xhr?
      render partial: 'edit' if request.xhr?
    else
      render action: 'show'
    end
  end

  def update
    if @child.update_attributes(params[:child])
      redirect_to :back
    else
      render action: 'show'
    end
  end
end
