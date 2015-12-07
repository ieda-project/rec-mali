# encoding: utf-8

class Child < ActiveRecord::Base
  include Csps::Exportable
  include Csps::Age

  validates_presence_of :first_name, :last_name, :if => :final?
  validates_inclusion_of :gender, in: [true, false], :if => :final?

  validates_presence_of :village_name, unless: proc { |u| u.temporary? || u.village }
  validates_presence_of :village, unless: proc { |u| u.temporary? || u.village_name.present? }
  validates_presence_of :mother, on: :create, unless: :temporary?

  validate do
    errors.add_on_blank form_vaccinations.keys unless @skip_vaccination_validations
  end

  after_save do
    remove_instance_variable :@skip_vaccination_validations if defined?(@skip_vaccination_validations)
  end

  belongs_to :village, class_name: 'Zone'
  globally_has_many :diagnostics, dependent: :destroy do
    def build_with_answers data={}
      diag = build data
      diag.child = proxy_owner
      diag.prebuild
    end
  end
  globally_has_one :last_visit,
                   class_name: 'Diagnostic', order: 'done_on DESC'
  has_attached_file :photo,
                    path: ':rails_root/public/repo/:zone_name/:uqid_:class_:attachment.:extension',
                    url: '/repo/:zone_name/:uqid_:class_:attachment.:extension',
                    default_url: '/images/missing.png'

  before_save :fill_fields

  scope :unfilled, conditions: { first_name: nil, last_name: nil }
  scope :temporary, conditions: { temporary: true }

  VACCINATIONS = {
    v_bcg: 'BCG',
    v_polio0: 'Polio-0',
    v_polio1: 'Polio-1',
    v_polio2: 'Polio-2',
    v_polio3: 'Polio-3',
    v_penta1: 'Penta-1',
    v_penta2: 'Penta-2',
    v_penta3: 'Penta-3',
    v_pneumo1: 'Pneumo-1',
    v_pneumo2: 'Pneumo-2',
    v_pneumo3: 'Pneumo-3',
    v_rota1: 'Rotavirus-1',
    v_rota2: 'Rotavirus-2',
    v_rota3: 'Rotavirus-3',
    v_measles: 'Antirougeoleux',
    v_yellow: 'Fiẻvre Jaune'
  }

  VACCINATION_AGES = {
    v_bcg: 0, 
    v_polio0: 0,
    v_polio1: 6.weeks,
    v_polio2: 10.weeks,
    v_polio3: 14.weeks,
    v_penta1: 6.weeks,
    v_penta2: 10.weeks,
    v_penta3: 14.weeks,
    v_pneumo1: 6.weeks,
    v_pneumo2: 10.weeks,
    v_pneumo3: 14.weeks,
    v_rota1: 6.weeks,
    v_rota2: 10.weeks,
    v_rota3: 14.weeks,
    v_measles: 9.months,
    v_yellow: 9.months
  }

  VACCINATION_TOP_AGES = {
    #v_bcg: 7.days
  }

  def skip_vaccination_validations!
    @skip_vaccination_validations = true
  end

  def displayed_vaccinations
    if born_on
      born = born_on.to_time
      now = Time.now
      VACCINATIONS.select do |k,v|
        va = VACCINATION_AGES[k]
        va.zero? || born + va < now
      end
    else
      {}
    end
  end

  def form_vaccinations
    if born_on
      born = born_on.to_time
      now = @now || Time.now
      VACCINATIONS.select do |k,v|
        va = VACCINATION_AGES[k]
        vta = VACCINATION_TOP_AGES[k]
        (va.zero? || born + va < now) && (!vta || born + vta > now)
      end
    else
      {}
    end
  end

  def with_date_as now
    @now = now
    yield
    remove_instance_variable :@now
  end

  def vaccinations
    VACCINATIONS.select { |k,v| send(k) }.values
  end

  def name
    "#{first_name} #{last_name}"
  end

  def sortable_name
    "#{last_name}, #{first_name}"
  end

  def final?
    not temporary?
  end

  delegate :index, :index_ratio, to: :last_visit, allow_nil: true
  for name, ratio in Diagnostic::INDICES do
    delegate name, ratio, to: :last_visit, allow_nil: true
  end

  protected

  def fill_fields
    self.village_name = nil if village_name.blank?
    self.cache_name = name.cacheize
  end
end
