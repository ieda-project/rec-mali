module Csps::Exportable
  MODELS = []
  def self.included model
    (MODELS << model.name).uniq!
    model.send :extend, ClassMethods
    model.send :attr_readonly, :imported
    model.send :before_save, :set_imported
    model.send :after_create, :fill_global_id
    model.metaclass.delegate :local, to: :scoped
  end

  def self.models
    MODELS.map &:constantize
  end

  protected

  def set_imported
    self.imported = global_id.present? && global_id !~ %r(#{Csps.site}/)
    true
  end

  def fill_global_id
    if global_id.blank?
      update_attribute :global_id, "#{Csps.site}/#{id}"
    end
    true
  end

  module ClassMethods
    def find_local id
      find_by_id_and_imported(id, false) or
        raise(ActiveRecord::RecordNotFound,
              "Couldn't find non-imported #{name} with ID=#{id}")
    end

    def import_from src
      columns = src.gets.chomp.split(?,).map &:intern
      catch :end do
        get = proc { src.gets or throw(:end) }
        loop do
          hash = {}
          columns.each do |col|
            type, line = get.().chomp.split '',2
            hash[col] = case type
              when ?:
                while line[-1] == "\\"
                  line = line[0...-1] + get.().chomp
                end
                line
              when ?t then true
              when ?f then false
              when ?n then nil
            end
          end

          obj = find_or_initialize_by_global_id hash[:global_id]
          puts hash.inspect
          puts
          obj.update_attributes! hash
        end
      end
    end

    def export_to out
      columns = (column_names - [ primary_key, 'imported' ]).sort
      out.puts columns.join(?,)

      local.order(:created_at).each do |record|
        columns.each do |col|
          v = record.send col
          out.puts case v
            when true  then ?t
            when false then ?f
            when nil   then ?n
            else ?: + v.to_s.gsub("\n", "\\\n")
          end
        end
      end
    end
  end
end
