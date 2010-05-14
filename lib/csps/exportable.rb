module Csps::Exportable
  MODELS = []
  def self.included model
    (MODELS << model.name).uniq!
    model.send :extend, ClassMethods
    model.send :attr_readonly, :imported
    model.send :before_create, :set_imported
    model.send :after_create, :fill_global_id
    model.metaclass.delegate :local, to: :scoped
  end

  def self.models
    MODELS.map &:constantize
  end

  protected

  def set_imported
    self.imported = false
    true
  end

  def fill_global_id
    update_attribute :global_id, "#{Csps.site}/#{id}"
  end

  module ClassMethods
    def find_local id
      find_by_id_and_imported(id, false) or
        raise(ActiveRecord::RecordNotFound,
              "Couldn't find non-imported #{name} with ID=#{id}")
    end
  end
end
