class Zone < ActiveRecord::Base
  acts_as_nested_set
  has_many :patients, class_name: 'Child'

  validates_uniqueness_of :name, scope: :parent_id

  scope :local, conditions: { here: true }
  scope :external, conditions: { here: false }
  scope :used, conditions: 'id IN (SELECT DISTINCT zone_id FROM children)'
  scope :points, conditions: { point: true }

  def option_title; name; end

  def to_select indent=0
    children.inject [] do |buf,i|
      [ *buf,
        ['&nbsp;'*indent + i.option_title, i.id],
        *i.to_select(indent+2) ]
    end
  end

  def occupy!
    transaction do
      raise 'Site already set' if Csps.site.present?
      if point
        update_attributes here: true
        children.update_all here: true
        self
      else
        raise 'Cannot occupy non-point'
      end
    end
  end

  def traverse t=0
    puts(' '*t + name + (point ? '*' : ''))
    children.each { |ch| ch.traverse t+2 }
    self
  end

  class << self
    def tree
      roots.each &:traverse
    end

    def csps
      find_by_here_and_point(true, true)
    end
  end
end
