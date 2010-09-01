module Csps::SyncProxy
  def self.for real_model
    returning Class.new(ActiveRecord::Base) do |model|
      model.module_eval do
        extend Csps::SyncProxy
        set_table_name real_model.table_name
        if real_model.columns_hash['temporary']
          scope :exportable_for,
                lambda { |i| where('temporary != ? AND global_id LIKE ?', true, "#{i.name}/%") }
        else
          scope :exportable_for,
                lambda { |i| where('global_id LIKE ?', "#{i.name}/%") }
        end
        self.inheritance_column = '__nonexistent__'
        self.primary_key = real_model.primary_key
      end
    end
  end

  def import_from src
    columns = src.gets.chomp.split(?,)
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

        obj = find_or_initialize_by_global_id hash.delete('global_id')
        obj.attributes = obj.attributes.merge hash
        obj.save!
      end
    end
  end

  def export_for out, zone
    columns = (column_names - [ primary_key ]).sort
    out.puts columns.join(?,)

    exportable_for(zone).order(:created_at).each do |record|
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
