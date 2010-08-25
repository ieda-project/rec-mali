class ChildrenController < ApplicationController
  login_required
  fetch 'Child', :also => :indices
  helper Ziya::HtmlHelpers::Charts
  helper Wopata::Ziya::HtmlHelpersFix
  before_filter :ask_for_csps, :except => :villages
  Search = Struct.new(:name, :born_on, :village_id)

  def index
    # Clean empty children (only photo)
    Child.unfilled.destroy_all
    @q = Search.from_hash params[:q]
    if params[:o].blank?
      params[:o] = 'last_visit_at'
      params[:d] = 'd'
    end
    @children = model.search(@q, params[:o], params[:d])
    @page = (params[:page] || '1').to_i
  end

  def calculations
    data = params[:d]
    weight = data[:weight].to_i
    height = data[:height].to_i
    months = data[:months].to_i
    gender = (data[:gender] == 'true')
    render json: {
      weight_age: [
        ((weight / Index.weight_age.gender(gender).near(months).y * 100).round(0) rescue nil),
        Index::WARNING['weight_age'], Index::ALERT['weight_age']],
      height_age: [
        ((height / Index.height_age.gender(gender).near(months).y * 100).round(0) rescue nil),
        Index::WARNING['height_age'], Index::ALERT['height_age']],
      weight_height: [
        ((weight / Index.weight_height.gender(gender).age_in_months(months).near(height).y * 100).round(0) rescue nil),
        Index::WARNING['weight_height'], Index::ALERT['weight_height']] }
  end

  def indices
    name = params[:name]
    diag = Diagnostic.find(params[:diagnostic]) if params[:diagnostic].present?
    if diag
      v, i = diag.index name
    else
      v, i = @child.index name
    end
    curve = Index.where(:name => Index::NAMES.index(name.gsub('_', '-'))).gender(@child.gender).age_in_months(@child.months).order(:x).all
    chart = Ziya::Charts::Line.new
    chart.add :theme, 'pimp'
    labels = curve.map(&:x).map {|e| ((e%6)==0 ? e : '')}
    chart.add :axis_category_text, labels
    chart.add(:series, '', curve.map do |c|
      {:value => c.y}
    end)
    chart.add(:series, '', curve.map do |c|
      if c == i
        {:value => v,
         :note => @child.name,
         :note_x => (i.x > (curve.last.x / 2) ? -15 : 15),
         :note_y => (v > (curve.last.y / 2) ? 30 : -30),
         :tooltip => v}
      else
        {}
      end
    end)
    render xml: chart.to_xml
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
  
  def villages
    if site = params[:site]
      Village.localize site
      redirect_to children_path
    end
  end

  protected

  def ask_for_csps
    if Village.local.count == 0
      render action: 'villages'
      false
    end
  end

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
