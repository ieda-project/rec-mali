module Csps::SyncProxy
  def self.for real_model
    returning Class.new(ActiveRecord::Base) do |model|
      model.module_eval do
        @real_model = real_model
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

  attr_reader :real_model

  def import_from path, zone
    dir = File.dirname path
    (real_model.attachment_definitions || []).each do |key,data|
      Dir.glob("#{dir}/*_#{real_model.name.pluralize.underscore}_#{key.to_s.pluralize}_*") do |f|
        rf = f.sub /^.*\/#{zone.folder_name}/, "#{Rails.root}/public/repo/#{zone.folder_name}"
        if !File.exist?(rf) || File.mtime(f) > File.mtime(rf)
          FileUtils.mkdir_p File.dirname(rf)
          FileUtils.cp f, rf
        end
      end
    end
    return unless File.exist? path

    conn = User.connection.instance_variable_get :@connection
    File.open(path, 'r') do |src|
      columns = src.gets.chomp.split(?,)
      conn.execute "BEGIN" ##########################################
      conn.execute "DELETE FROM #{table_name} WHERE global_id LIKE ?", "#{zone.name}/%"
      catch :end do
        get = proc { src.gets or throw(:end) }
        loop do
          keys, placeholders, values = %w(zone_id), %w(?), [zone.id]
          columns.each do |col|
            keys << col
            type, line = get.().chomp.split '',2
            value = case type
              when ?:
                while line[-1] == "\\"
                  line = line[0...-1] + get.().chomp
                end
                line
              when ?t, ?f then type
              when ?n
                placeholders << 'NULL'
                nil
              else raise("Bad dump")
            end
            if value
              placeholders << '?'
              values << value
            end
          end

          conn.execute(
            "INSERT INTO #{table_name} (#{keys.join(',')}) VALUES (#{placeholders.join(',')})", 
            values)
        end
      end
      conn.execute "COMMIT" #########################################
      conn.execute "VACUUM"
    end
  end

  def export_for path, zone
    dir = File.dirname path
    (real_model.attachment_definitions || []).each do |key,data|
      Dir.glob("#{Rails.root}/public/repo/#{zone.folder_name}/*_#{real_model.name.pluralize.underscore}_#{key.to_s.pluralize}_*") do |rf|
        f = rf.sub /^.*\/#{zone.folder_name}/, dir
        if !File.exist?(f) || File.mtime(rf) > File.mtime(f)
          FileUtils.mkdir_p File.dirname(f)
          FileUtils.cp rf, f
        end
      end
    end

    File.open(path, 'w') do |out|
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
      end
    end
  end
end
