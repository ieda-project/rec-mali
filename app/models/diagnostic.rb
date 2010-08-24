class Diagnostic < ActiveRecord::Base
  include Csps::Exportable
  serialize :failed_classifications
  globally_belongs_to :child
  globally_belongs_to :author, class_name: 'User'
  has_and_belongs_to_many :classifications do
    def for illness
      select { |c| c.illness_id == illness.id }
    end
  end
  globally_has_many :sign_answers, include: :sign, order: 'signs.sequence',
                    after_add: :clear_classifications,
                    after_remove: :clear_classifications do
    def add data
      sign = data.delete(:sign) || Sign.find(data.delete(:sign_id)) rescue nil
      existing = detect { |i| i.sign_id == sign.id }
      if existing
        existing.attributes = data
        if existing.changed?
          existing.save
          proxy_owner.send :clear_classifications
        end
      else
        returning(sign ? sign.build_answer(data) : SignAnswer.new(data)) { |sa| push sa }
      end
    end
    def for illness
       select { |a| a.sign.illness_id == illness.id }
    end
    def to_hash
      returning({}) do |hash|
        includes(sign: :illness).each do |answer|
          hash.store answer.sign.full_key, answer.raw_value
        end
      end
    end
  end
  globally_has_many :illness_answers

  scope :between, lambda {|d1, d2| {:conditions => ['done_on > ? and done_on <= ?', d1, d2]}}

  before_create :set_date
  after_create :update_child

  validates_presence_of :child, :height, :weight
  validates_numericality_of :mac, :only_integer => true, :allow_blank => true
  validates_numericality_of :height, :weight
  validate :validate_answers

  def to_hash
    returning(sign_answers.to_hash) do |hash|
      for field in %w(age months muac wfa hfa wfh)
        hash["enfant.#{field}"] = send field
      end
    end
  end

  def muac; mac; end

  def reference_date
    created_at ? created_at.to_date : Date.today
  end

  def age
    reference_date.full_years_from(child.born_on)
  end

  def months
    reference_date.full_months_from(child.born_on)
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
      Index.weight_height.gender(child.gender).near(height) ]
  end

  def index name
    send(name) if INDICES[name.to_s]
  end

  def index_ratio name
    if INDICES[name.to_s]
      val, i = send name
      (val / i.y * 100).round(0) rescue '-'
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
    sign_ids = sign_answers.map(&:sign_id).to_rhash
    Sign.order(:sequence).each do |sign| 
      sign_answers << sign.answer_class.new(sign: sign) unless sign_ids[sign.id]
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

  protected

  def update_child
    child.update_attribute :last_visit_at, created_at
  end

  def set_date
    self.done_on ||= Time.now
  end

  def clear_classifications obj=nil
    classifications.clear
  end

  def validate_answers
    errors[:sign_answers] << :invalid if prebuild.sign_answers.reject(&:valid?).any?
  end
end
