class Zone < ActiveRecord::Base
  acts_as_nested_set
  has_many :patients, class_name: 'Child'
  has_many :serial_numbers do
    def get model
      model = model.superclass while model.superclass != ActiveRecord::Base
      find_or_initialize_by_model model.name
    end
    def [] model
      get(model).value
    end
    def []= model, value
      get(model).update_attributes! value: value, exported: false
    end
  end
  def modified! model
    serial_numbers.get(model).modified!
  end
  def exported! model
    serial_numbers.get(model).exported!
  end

  validates_uniqueness_of :name, scope: :parent_id
  validates_uniqueness_of :here, if: :here

  scope :used, where('id IN (SELECT DISTINCT zone_id FROM children)')
  scope :used_villages, where('id IN (SELECT DISTINCT village_id FROM children)')
  scope :villages, where(village: true)

  scope :external, where(here: false)
  scope :accessible, where(accessible: true)
  scope :points, where(point: true)
  scope :restoring, where(restoring: true)
  scope :importable_points, where(
    "restoring = :t OR ((here != :t OR here IS NULL) AND accessible = :t AND point = :t)", t: true)
  scope :exportable_points, accessible.points

  scope :synced, where('last_import_at IS NOT NULL OR last_export_at IS NOT NULL')

  before_save do |rec|
    rec.village = rec.parent && rec.parent.point?
    true
  end

  def option_title; name; end
  def folder_name; name.gsub(' ', '_').downcase; end
  alias file_name folder_name

  def upchain
    parent ? [ parent, *parent.upchain ] : []
  end

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

  def occupy! restoring=false
    transaction do
      raise 'Site already set' if Csps.site.present?
      update_attributes here: true, accessible: true, restoring: restoring
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

    def reload_csps
      @csps = find_by_here(true)
    end

    def csps
      @csps || find_by_here(true)
    end
    alias here csps

    def unsynced
      Zone.where(
        '(last_import_at IS NOT NULL AND last_import_at < :old) OR (last_export_at IS NOT NULL AND last_export_at < :old)',
        old: 90.days.ago).count
    end
  end
end
