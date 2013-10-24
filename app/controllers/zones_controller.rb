class ZonesController < ApplicationController
  layout 'application'

  before_filter :root_zone_required
  admin_required
  fetch 'Zone'
  before_filter :must_be_editable, only: [:edit, :update, :destroy]

  def index
  end

  def new
    @zone = Zone.new
  end

  def create
    if Zone.create params[:zone].keep(%w(name parent_id)).merge(custom: true)
      see_other zones_path
    else
      render action: :new
    end
  end

  def edit
  end

  def update
    if @zone.update_attributes params[:zone].keep(%w(name parent_id))
      see_other zones_path
    else
      render action: :new
    end
  end

  def destroy
    @zone.destroy
    see_other zones_path
  end

  protected

  def root_zone_required
    Zone.csps.root? or not_found
  end

  def must_be_editable
    @zone.editable? or not_found
  end
end
