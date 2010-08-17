class Child < ActiveRecord::Base
  include Csps::Exportable
  belongs_to :village
  has_many :child_photos
  has_many :diagnostics
  has_one :last_visit,
          class_name: 'Diagnostic',
          order: 'id DESC'
  has_attached_file :photo,
                    styles: { thumbnail: '110x130' }

  before_save :fill_cache_fields
  
  scope :unfilled, :conditions => {:first_name => nil, :last_name => nil}

  VACCINATIONS = {
    bcg_polio0: 'BCG/Polio-0',
    penta1_polio1: 'PENTA-1/Polio-1',
    penta2_polio2: 'PENTA-2/Polio-2',
    penta3_polio3: 'PENTA-3/Polio-3',
    measles: 'Antirougeoleux' }

  def vaccinations
    VACCINATIONS.select { |k,v| send(k) }.map &:last
  end

  def age
    born_on ? ((Date.today - born_on) / 365).to_i : nil
  end
  
  def name
    "#{first_name} #{last_name}"
  end
  
  def self.group_stats_by case_status, rs
    m = self.minimum(:created_at)
    return {} if m.nil?
    d1 = m.beginning_of_month
    d2 = d1.next_month.to_date
    grs = {}
    while Date.today.next_month.beginning_of_month >= d2
      k = dates2key(d1)
      grs[k] = 0
      rs.each do |r|
        grs[k] += 1 if r.created_at >= d1 and r.created_at < d2
      end
      d1 = d1.next_month
      d2 = d2.next_month
    end
    grs
  end
  
  def self.dates2key d
    "#{d.year}-#{sprintf("%02d", d.month)}"
  end

  protected

  @@iconv = Iconv.new('ASCII//IGNORE//TRANSLIT', 'UTF-8')
  def fill_cache_fields
    self.cache_name = name.cacheize
  end
end
