class Village < ActiveRecord::Base
  has_many :children

  validates_uniqueness_of :name, :scope => [:csps, :district]

  scope :local, :conditions => {:here => true}
  scope :external, :conditions => {:here => false}

  scope :for_csps, lambda {|csps| {:conditions => {:csps => csps}}}
  scope :used, {:conditions => 'id IN (SELECT DISTINCT village_id FROM children)'}

  def self.to_select
    order('csps, name').map { |i| [ "#{i.csps} &raquo; #{i.name}".html_safe, i.id.to_s ] }
  end
  
  def self.site_select
    select('csps').group('csps').map { |i| [i.csps, i.csps] }
  end
  
  def self.localize csps
    local.update_all(:here => false)
    for_csps(csps).update_all(:here => true)
  end
  
  def self.csps
    if village = local.first
      village.csps
    end
  end
end
