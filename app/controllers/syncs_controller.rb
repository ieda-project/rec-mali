class SyncsController < ApplicationController
  login_required

  def show
    back 'Rechercher un patient', children_path
  end
end
