class Diagnostic < ActiveRecord::Base
  include Csps::Exportable
  include Csps::Age

  enum :kind, %w(first initial follow)
  #enum :distance, %w(0_4 5_9 10)

  state_machine :state, initial: :opened do
    # opened, filled, calculated, treatments_selected, closed
    state :filled, :calculated, :treatments_selected, :medicines_selected, :closed do
      validate do
        validates_size_of :sign_answers, minimum: 1
      end
    end

    state :calculated, :treatments_selected, :medicines_selected, :closed do
      validate do
        validates_size_of :results, minimum: 1
      end
    end

    state :treatments_selected, :medicines_selected, :closed do
      def treatments_required?
        true
      end
    end

    state :medicines_selected, :closed do
      validate do
        dupes_grouped.each do |gr|
          next if gr.none?(&:mandatory)
          unless gr.any? { |i| ordonnance.include?(i.id) }
            errors.add :ordonnance, :invalid
            break
          end
        end
      end
    end

    state :treatments_selected, :medicines_selected, :closed do
      def medicine_options?
        optional_prescriptions.any? || dupe_prescriptions.any?
      end

      def optional_prescriptions
        Set.new(all_prescriptions.reject(&:mandatory))
      end

      def dupe_prescriptions
        @dupe_prescriptions ||= dupes_grouped.inject(Set.new) { |m,i| m + i }
      end

      def all_prescriptions
        @all_prescriptions ||=
          begin
            results.to_display(prescriptions: :medicine).inject([]) do |m,i|
              m + i.prescriptions.select { |p| p.valid_for? self }
            end
          end
      end

      def dupes_grouped
        {}.tap do |h|
          results.to_display(prescriptions: :medicine).each do |res|
            res.prescriptions.each do |p|
              next unless p.valid_for?(self)
              (h[p.medicine.group_key] ||= []) << p
            end
          end
        end.values.select { |i| i[1] }
      end
    end

    state :medicines_selected, :closed do
      def listed_prescriptions
        results.to_display(prescriptions: :medicine).inject([]) do |m,i|
          m + i.prescriptions.select { |p| p.valid_for?(self) && (p.mandatory? || ordonnance.include?(p.id)) }
        end
      end
    end

    state :opened, :filled, :calculated do
      def treatments_required?
        false
      end
    end

    event :fill do
      transition any => :filled, if: ->(d) { d.sign_answers.any? }
    end

    event :finish_calculations do
      transition :filled => :treatments_selected, if: ->(d) { d.results.all? &:finalized? }
      transition :filled => :calculated
    end

    event :select_treatments do
      transition :calculated => :treatments_selected, if: ->(d) { d.results.all? &:finalized? }
    end

    event :select_medicines do
      transition :treatments_selected => :medicines_selected, if: ->(d) { d.results.all? &:finalized? }
    end

    event :close do
      transition :medicines_selected => :closed
    end

    after_transition any => :filled do |diag|
      diag.results.destroy_all
    end
  end

  # A scope for each state
  state_machine.states.each do |state|
    scope state.name, where('state = ?', state.name)
  end

  def ordonnance
    @ordonnance ||=
    begin
      if ord = read_attribute(:ordonnance)
        Set.new(ord.split(' ').map(&:to_i))
      else
        Set.new
      end
    end
  end

  def ordonnance= arr
    case arr
      when Set
        @ordonnance = arr
        arr = arr.to_a
      when Hash
        arr = arr.values.map &:to_i
        @ordonnance = Set.new(arr)
      else
        @ordonnance = Set.new(arr)
    end
    write_attribute :ordonnance, arr.join(' ')
  end

  def prescriptions
    @prescriptions ||= Prescription.find(*ordonnance)
  end

  serialize :failed_classifications

  globally_belongs_to :child
  globally_belongs_to :author, class_name: 'User'
  globally_has_many :results, dependent: :destroy do
    def to_display incl=nil
      high = Classification::LEVELS.index :high
      set = with_treatment
      set = set.includes(incl) if incl
      set.to_a.tap do |out|
        if out.any? { |r| r.classification.level == high }
          out.reject! { |r| r.classification.level != high }
        end
      end
    end
  end

  has_many :classifications, finder_sql: ->(wut) { ["SELECT c.* FROM classifications c INNER JOIN results r ON c.id = r.classification_id WHERE r.diagnostic_uqid = ?", uqid] } do
    def for illness
      select { |c| c.illness_id == illness.id }
    end
    #def on_treatment_list
    #  level = Classification::LEVELS.index :high
    #  (short = select { |c| c.level == level && c.treatment.present? }).empty? ?
    #    select { |c| c.treatment.present? } :
    #    short
    #end
  end

  globally_has_many :sign_answers, dependent: :destroy, include: :sign, order: 'signs.sequence, signs.id' do
    def add data
      sign = data.delete(:sign) || Sign.find(data.delete(:sign_id)) rescue nil
      existing = detect { |i| i.sign_id == sign.id }
      if existing
        existing.attributes = existing.attributes.merge(data)
        existing.save if existing.changed?
      else
        (sign ? sign.build_answer(data) : SignAnswer.new(data)).tap { |sa| push sa }
      end
    end
    def process data
      if data.present?
        data.each_value { |a| add a }
        proxy_owner.fill
      end
    end
    def for illness
      select { |a| a.sign.illness_id == illness.id }
    end
    def to_hash
      {}.tap do |hash|
        includes(sign: :illness).each do |answer|
          hash.store answer.sign.full_key, answer.raw_value
        end
      end
    end
  end
  globally_has_many :illness_answers, dependent: :destroy

  scope :between, lambda {|d1, d2| {:conditions => ['done_on > ? and done_on <= ?', d1, d2]}}

  before_validation do
    for i in [:comments, :other_problems]
      val = read_attribute(i)
      val = val.strip.gsub("\r", '') if val.present?
      write_attribute i, val.blank? ? nil : val
    end
    if new_record?
      self.done_on ||= Time.now
      self.born_on ||= child.born_on if child
      self.kind_key ||= (child && child.diagnostics.count > 0) ? 'initial' : 'first'
      fill false
    end
  end

  before_save do
    if born_on_changed? && child && child.born_on != born_on
      child.born_on = born_on
    end
    self.month ||=
      begin
        ref = (done_on.day >= 26) ? done_on + 6.days : done_on
        ref.year*100 + ref.month
      end
  end

  after_save do
    if born_on_changed? && child && child.born_on != born_on
      child.update_attribute :born_on, born_on
    end
  end

  after_create do
    child.update_attribute :last_visit_at, created_at
  end

  validates_presence_of :child
  validates_presence_of :height, :weight, :temperature
  validates_presence_of :mac, if: ->(diag) { diag.child && diag.child.months >= 6 }
  validates_numericality_of :mac, only_integer: true, allow_blank: true
  validates_numericality_of :height, :weight, :temperature
  validate do
    if of_valid_age?
      errors[:sign_answers] << :invalid if prebuild.sign_answers.reject(&:valid?).any?
    elsif done_on.to_date < born_on || done_on > Time.now
      errors[:done_on] << :invalid
    end
  end

  accepts_nested_attributes_for :results

  def open?
    not closed?
  end

  def last?
    child.diagnostics.order('done_on DESC').select('id').first.id == id
  end

  def retired_signs?
    sign_answers.includes(:sign).any? { |sa| sa.sign.retired? }
  end

  def editable_by? user
    Csps.point? && author == user && !closed?
  end

  def deletable_by? user
    author == user && last? && super
  end

  def to_hash
    sign_answers.to_hash.tap do |hash|
      for field in %w(age months muac wfa hfa wfh height weight)
        hash["enfant.#{field}"] = send field
      end
    end
  end

  def muac; mac; end

  def age_reference_date
    done_on ? done_on.to_date : Date.today
  end

  INDICES = {
    'weight_age' => 'wfa',
    'height_age' => 'hfa',
    'weight_height' => 'wfh' }

  def weight_age
    [ weight,
      Index.weight_age.gender(child.gender).near(days) ]
  end

  def height_age
    [ height,
      Index.height_age.gender(child.gender).near(days) ]
  end

  def weight_height
    [ weight,
      Index.weight_height.gender(child.gender).age_in_days(child.days).near(height) ]
  end

  def index name
    send(name) if INDICES[name.to_s]
  end

  def index_ratio name
    if INDICES[name.to_s]
      val, i = send name
      Diagnostic.index_ratio val, i
    end
  end

  def z_score name
    if INDICES[name.to_s]
      val, i = send name
      Diagnostic.z_score val, i
    end
  end

  def self.index_ratio value, index
    (value / index.y * 100).round(0)
  end
  def self.z_score value, index
    index.score value
  end

  def self.scores name, gender, days, weight, height
    i, val = case name
      when 'height_age' then [Index.height_age.gender(gender).near(days), height]
      when 'weight_age' then [Index.weight_age.gender(gender).near(days), weight]
      when 'weight_height' then [Index.weight_height.gender(gender).age_in_days(days).near(height), weight]
      else nil
    end
    [Diagnostic.index_ratio(val, i), Diagnostic.z_score(val, i)]
  end

  for name, ratio in INDICES
    module_eval "def #{ratio}; index_ratio :#{name}; end", __FILE__, __LINE__
  end

  def height= val
    write_attribute :height, val.to_s.gsub(',', '.')
  end

  def weight= val
    write_attribute :weight, val.to_s.gsub(',', '.')
  end

  def temperature= val
    write_attribute :temperature, val.to_s.gsub(',', '.')
  end

  def type_name
    '-'
  end

  def prebuild
    self.born_on ||= child.born_on if child
    if age_group
      sign_ids = sign_answers.map(&:sign_id).rhashize
      Sign.where(age_group: age_group, retired: false).order(:sequence).each do |sign|
        sign_answers << sign.answer_class.new(sign: sign) unless sign_ids[sign.id]
      end
    else
      raise 'Age group cannot be determined, diagnostic cannot be prebuilt'
    end
    self
  end

  class << self
    def search_columns
      column_names
    end

    def group_stats_by case_status, rs
      # TODO
      m = self.minimum :done_on
      return {} if m.nil?
      d1 = m.beginning_of_month
      d2 = d1.next_month
      grs = {}
      while Date.today.next_month.beginning_of_month >= d2
        k = "#{d1.year}-#{sprintf("%02d", d1.month)}"
        grs[k] = 0
        rs.each do |r|
          grs[k] += 1 if r.done_on < d2
        end
        d1 = d1.next_month
        d2 = d2.next_month
      end
      grs
    end

    def age_reference_field
      :done_on
    end

    def rewrite_query_conditions cond
      att, val = cond['field'], cond['value']
      if att == 'classifications.name'
        if c = Classification.find_by_name(val)
          [ 'results.classification_id', c.id ]
        else
          raise "No such classification: #{val}"
        end
      else
        [ att, val ]
      end
    end
  end

  # Needed by Csps::Age
  def temporary?
    false
  end
end
