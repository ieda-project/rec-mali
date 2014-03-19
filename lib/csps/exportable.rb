require 'set'
require 'base32'

module Csps::Exportable
  extend ActiveSupport::Concern
  MODELS = Set.new

  included do
    # Ignore namespaced models (temporary ones only for migration)
    MODELS << name unless name.include?('::')

    @gbt = Set.new

    before_save :fill_uqid
    after_save :register_change
    validate :validate_csps
    belongs_to :zone
    scope :with_global_refs, ->() { includes(*global_refs) }
  end

  def self.models
    Dir.glob("#{Rails.root}/app/models/*.rb").each do |f|
      File.basename(f)[0..-4].camelize.constantize
    end
    MODELS.map &:constantize
  end

  def zone_name
    zone.name
  end

  def deletable_by? user=nil
    if Csps.point? && zone == Zone.csps
      if lsoa = Zone.csps.last_sync_op_at
        created_at > lsoa
      else
        true
      end
    else
      false
    end
  end

  def identifier
    Base32.encode(uqid).readable
  end

  protected

  def fill_uqid
    if uqid.blank? || uqid.zero?
      zid = Zone.csps.id
      self.uqid = (zid << 48) | (Time.now.to_f * 1000).to_i
      self.zone_id = zid
    end
    true
  end

  def validate_csps
    errors[:uqid] << :invalid if Csps.site.blank?
  end

  def register_change
    zone.modified! self.class if changed?
  end

  module ClassMethods
    def global_refs
      @gbt.to_a
    end

    def globally_has_many *args, &blk
      opts = args.extract_options!
      n = opts.delete(:as) || name.singularize.underscore
      args.each do |i|
        has_many i, opts.merge(
          primary_key: :uqid,
          foreign_key: "#{n}_uqid"), &blk
      end
    end

    def globally_has_one *args, &blk
      opts = args.extract_options!
      args.each do |i|
        has_one i, opts.merge(
          primary_key: :uqid,
          foreign_key: "#{name.underscore}_uqid"), &blk
      end
    end

    def globally_belongs_to *args, &blk
      opts = args.extract_options!
      @gbt += args
      args.each do |i|
        belongs_to i, opts.merge(
          primary_key: :uqid,
          foreign_key: "#{i}_uqid"), &blk
      end
    end

    def last_modified zone
      Time.at where(zone_id: zone_id).order('updated_at DESC').first.updated_at.to_i
    rescue
      nil
    end
  end
end
