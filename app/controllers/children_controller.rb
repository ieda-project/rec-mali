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
  end

  def create
    @child = Child.new params[:child]
    if @child.save
      see_other child_path
    else
      unprocessable action: :new
    end
  end
end
