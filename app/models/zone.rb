class Zone < ActiveRecord::Base
  acts_as_nested_set
  has_many :patients, class_name: 'Child'

  validates_uniqueness_of :name, scope: :parent_id
  validates_uniqueness_of :here, if: :here

  scope :used, where('id IN (SELECT DISTINCT zone_id FROM children)')
  scope :used_villages, where('id IN (SELECT DISTINCT village_id FROM children)')
  scope :villages, where(village: true)

  scope :external, where(here: false)
  scope :accessible, where(accessible: true)
  scope :points, where(point: true)
  scope :importable_points, external.accessible.points
  scope :exportable_points, accessible.points

  scope :synced, where('last_import_at IS NOT NULL OR last_export_at IS NOT NULL')

  before_save do |rec|
    rec.village = rec.parent && rec.parent.point?
    true
  end

  def option_title; name; end
  def folder_name; name.gsub(' ', '_'); end

  def ever_imported?; last_import_at?; end
  def ever_exported?; last_export_at?; end
  def ever_synced?; last_import_at? || last_export_at?; end

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
      descendants.update_all accessible: true
      self
    end
  end

  def traverse t=0
    puts(' '*t + name + (point ? '*' : '') + " #{lft}:#{rgt}")
    children.each { |ch| ch.traverse t+2 }
    self
  end

  def unsynced?
    old = 90.days.ago
    (last_import_at && last_import_at < old) || (last_export_at && last_export_at < old)
  end

  class << self
    def tree
      roots.each &:traverse
    end

    def csps
      find_by_here true
    end
    alias here csps

    def unsynced
      Zone.where(
        '(last_import_at AND last_import_at < :old) OR (last_export_at AND last_export_at < :old)',
        old: 90.days.ago).count
    end
  end
end
