module Csps::Exportable
  MODELS = []
  def self.included model
    (MODELS << model.name).uniq!
    model.send :scope, :local, conditions: [ 'imported != ?', true ]
    model.send :extend, ClassMethods
    model.send :attr_readonly, :imported
    model.send :after_create, :fill_global_id
    model.send :validate, :validate_csps
  end

  def self.models
    MODELS.map &:constantize
  end

  protected

  def fill_global_id
    if global_id.blank?
      update_attribute :global_id, "#{Csps.site}/#{id}"
    end
    true
  end

  def validate_csps
    errors[:global_id] << :invalid if Csps.site.blank?
  end

  module ClassMethods
    def globally_has_many *args, &blk
      opts = args.extract_options!
      args.each do |i|
        has_many i, opts.merge(
          primary_key: :global_id,
          foreign_key: "#{name.singularize.underscore}_global_id"), &blk
      end
    end

    def globally_has_one *args, &blk
      opts = args.extract_options!
      args.each do |i|
        has_one i, opts.merge(
          primary_key: :global_id,
          foreign_key: "#{name.underscore}_global_id"), &blk
      end
    end

    def globally_belongs_to *args, &blk
      opts = args.extract_options!
      args.each do |i|
        belongs_to i, opts.merge(
          primary_key: :global_id,
          foreign_key: "#{i}_global_id"), &blk
      end
    end

    def find_local id
      find_by_id_and_imported(id, false) or
        raise(ActiveRecord::RecordNotFound,
              "Couldn't find non-imported #{name} with ID=#{id}")
    end

    def last_modified zone
      Time.at where('global_id LIKE ?', "#{zone.name}/%").order('updated_at DESC').first.updated_at.to_i
    rescue
      nil
    end
  end
end
