module Csps::SyncProxy
  def self.for real_model
    returning Class.new(ActiveRecord::Base) do |model|
      model.module_eval do
        extend Csps::SyncProxy
        set_table_name real_model.table_name
        if real_model.columns_hash['temporary']
          scope :exportable_for,
                lambda { |i| where('temporary != ? AND zone_id = ?', true, i.id) }
        else
          scope :exportable_for,
                lambda { |i| where(zone_id: i.id) }
        end
        self.inheritance_column = '__nonexistent__'
        self.primary_key = real_model.primary_key
      end
    end
  end

  def import_from src, zone
    columns = src.gets.chomp.split(?,)
    count = 0
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
        obj.zone_id = zone.id
        obj.save!
        count += 1
      end
    end
    count
  end

  def export_for out, zone
    columns = (column_names - [ primary_key, 'zone_id' ]).sort
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
    end.size
  end
end
