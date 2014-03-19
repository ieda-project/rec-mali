class Child < ActiveRecord::Base
  include Csps::Exportable
  include Csps::Age

  validates_presence_of :first_name, :last_name, :if => :final?
  validates_inclusion_of :gender, in: [true, false], :if => :final?

  validates_presence_of :village_name, unless: proc { |u| u.temporary? || u.village }
  validates_presence_of :village, unless: proc { |u| u.temporary? || u.village_name.present? }
  validates_presence_of :mother, on: :create

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
    bcg_polio0: 'BCG/Polio-0',
    penta1_polio1: 'PENTA-1/Polio-1',
    penta2_polio2: 'PENTA-2/Polio-2',
    penta3_polio3: 'PENTA-3/Polio-3',
    measles: 'Antirougeoleux' }

  def vaccinations
    VACCINATIONS.select { |k,v| send(k) }.map &:last
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

  def self.dates2key d
    "#{d.year}-#{sprintf("%02d", d.month)}"
  end

  protected

  def fill_fields
    self.village_name = nil if village_name.blank?
    self.cache_name = name.cacheize
  end
end
