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

  protected

  @@iconv = Iconv.new('ASCII//IGNORE//TRANSLIT', 'UTF-8')
  def fill_cache_fields
    self.cache_name = name.cacheize
  end
end
