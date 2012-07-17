class Diagnostic < ActiveRecord::Base
  include Csps::Exportable
  include Csps::Age

  state_machine :state, initial: :opened do
    # opened, filled, calculated, treatments_selected, closed
    state :filled, :calculated, :treatments_selected, :closed do
      validate do
        validates_size_of :sign_answers, minimum: 1
      end
    end
    state :calculated, :treatments_selected, :closed do
      validate do
        validates_size_of :results, minimum: 1
      end
    end
    state :treatments_selected, :closed do
      def treatments_required?
        true
      end
    end
    state :closed do
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

    event :close do
      transition :treatments_selected => :closed
    end

    after_transition any => :filled do |diag|
      diag.results.destroy_all
    end
  end

  serialize :failed_classifications
  globally_belongs_to :child
  globally_belongs_to :author, class_name: 'User'
  globally_has_many :results do
    def to_display
      high = Classification::LEVELS.index :high
      with_treatment.to_a.tap do |out|
        if out.any? { |r| r.classification.level == high }
          out.reject! { |r| r.classification.level != high }
        end
      end
    end
  end
  has_many :classifications, through: :results do
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
  globally_has_many :sign_answers, include: :sign, order: 'signs.sequence' do
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
  globally_has_many :illness_answers

  scope :between, lambda {|d1, d2| {:conditions => ['done_on > ? and done_on <= ?', d1, d2]}}

  before_validation do
    if new_record?
      self.done_on ||= Time.now
      self.born_on ||= child.born_on if child
      fill false
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
      Index.weight_age.gender(child.gender).near(months) ]
  end

  def height_age
    [ height,
      Index.height_age.gender(child.gender).near(months) ]
  end

  def weight_height
    [ weight,
      Index.weight_height.gender(child.gender).age_in_months(child.months).near(height) ]
  end

  def index name
    send(name) if INDICES[name.to_s]
  end

  def index_ratio name
    if INDICES[name.to_s]
      val, i = send name
      (val / i.y * 100).round(0) #rescue '-'
    end
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

  def type_name
    '-'
  end

  def prebuild
    self.born_on ||= child.born_on if child
    if age_group
      sign_ids = sign_answers.map(&:sign_id).rhashize
      Sign.where(age_group: age_group).order(:sequence).each do |sign| 
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
  end
end
