class Zone < ActiveRecord::Base
  acts_as_nested_set
  has_many :patients, class_name: 'Child'

  validates_uniqueness_of :name, scope: :parent_id
  validates_uniqueness_of :here, if: :here

  scope :external, conditions: { here: false }
  scope :used, conditions: 'id IN (SELECT DISTINCT zone_id FROM children)'
  scope :points, conditions: { point: true }
  scope :accessible, conditions: { accessible: true }

  def option_title; name; end

  def to_select opts={}
    if opts[:include_self]
      [[ name, id ], *_to_select(2) ]
    else
      _to_select 0
    end
  end

  def _to_select indent
    children.order(:name).inject [] do |buf,i|
      [ *buf,
        ['&nbsp;'*indent + i.name, i.id],
        *i._to_select(indent+2) ]
    end
  end
  protected :_to_select

  def occupy!
    transaction do
      raise 'Site already set' if Csps.site.present?
      update_attributes here: true, accessible: true
      children.update_all accessible: true
      self
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
      find_by_here true
    end
    alias here csps
  end
end
