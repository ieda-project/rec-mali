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
  end

  def create
    puts params[:child].inspect
    diag = params[:child].delete(:diagnostic)
    answers = diag.delete(:sign_answers).values
    @child = Child.new params[:child]
    @diagnostic = @child.diagnostics.build diag
    @diagnostic.child = @child
    @diagnostic.author = current_user
    answers.each { |a| @diagnostic.sign_answers.build(a) }

    if @child.save
      see_other @child
    else
      render action: 'new'
    end
  end
end
