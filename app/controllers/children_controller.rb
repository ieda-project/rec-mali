require 'stringio'
require 'base64'

class ChildrenController < ApplicationController
  login_required
  fetch 'Child', :also => :indices
  helper Ziya::HtmlHelpers::Charts
  helper Wopata::Ziya::HtmlHelpersFix

  class Search < Struct.new(:name, :born_on, :village_id, :identifier)
    def to_params_hash
      @hash ||= {}.tap do |h|
        h[:name] = name if name.present?
        h[:born] = born_on if born_on.present?
        h[:village] = village_id if village_id.present?
        h[:identifier] = identifier if identifier.present?
      end
    end
  end

  before_filter :rewrite_photo, only: [:update, :temp]

  def index
    # Clean empty children (only photo)
    Child.unfilled.destroy_all

    @q = Search.from_hash params
    @orig_name = @q.name.dup if @q.name

    if params[:o].blank?
      order = 'last_visit_at'
      params[:d] = 'd'
    elsif params[:o] == 'zone'
      order = 'zones.name, children.village_name'
    else
      order = params[:o]
    end

    @children =
      begin
        model.search(@q, order, params[:d])
      rescue => e
        @error = e.message
        []
      end

    @page = (params[:page] || '1').to_i
  end

  def calculations
    data = params[:d]
    weight = data[:weight].to_f
    height = data[:height].to_f
    days = data[:days].to_f
    gender = (data[:gender] == 'true')
    render json: {
      weight_age: [
        *Diagnostic.scores('weight_age', gender, days, weight, height),
        Index::WARNING['weight_age'], Index::ALERT['weight_age']],
      height_age: [
        *Diagnostic.scores('height_age', gender, days, weight, height),
        Index::WARNING['height_age'], Index::ALERT['height_age']],
      weight_height: [
        *Diagnostic.scores('weight_height', gender, days, weight, height),
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
    labels = if name == 'weight_height'
      curve.map(&:x).map {|e| ((e%6)==0 ? e : '')}
    else
      curve.map(&:x).map {|e| ((e%200)==0 ? (e/30).round : '')}
    end
    chart.add :axis_category_text, labels
    chart.add(:series, '', curve.map do |c|
      {:value => c.y}
    end)
    chart.add(:series, '', curve.map do |c|
      {:value => c.sd3neg}
    end)
    chart.add(:series, '', curve.map do |c|
      {:value => c.sd3}
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
    back 'Liste des patients', children_path
  end

  def new
    return see_other(children_path) unless Zone.csps.point?
    @child = Child.new
    @diagnostic = @child.diagnostics.build # Cannot be prebuilt here!
    back 'Liste des patients', children_path
  end

  def questionnaire
    #if request.xhr?
      @child = Child.new born_on: params[:born_on]
      @diagnostic = @child.diagnostics.build_with_answers
      render layout: false
    #else
    #  not_found
    #end
  end

  def create
    return see_other(children_path) unless Zone.csps.point?

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
    @child = Child.new @data.merge(temporary: true)
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
    display_updated @child.update_attributes(@data)
  end

  def destroy
    if @child.deletable_by? current_user
      @child.destroy
      see_other children_path
    else
      denied
    end
  end

  protected

  def rewrite_photo
    @data = data = params[:child]
    if data && data['photo'].is_a?(String)
      raw = data.delete('photo')
      raw.tr! ' ', '+'
      sio = StringIO.new(Base64.decode64(raw))
      def sio.content_type; 'image/png'; end
      def sio.original_filename; 'hcam.png'; end
      data['photo'] = sio
    end
    true
  end

  def display_updated success
    respond_to do |wants|
      wants.html do
        success ? redirect_to(:back) : render(action: :show)
      end
      wants.json do
        if success
          render json: { photo: @child.photo.url }
        else
          render nothing: true, status: 422
        end
      end
    end
  end
end
