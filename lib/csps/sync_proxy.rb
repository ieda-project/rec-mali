module Csps::SyncProxy
  def self.for real_model
    Class.new(ActiveRecord::Base).tap do |model|
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

  def bare_connection
    @conn ||= real_model.connection.instance_variable_get(:@connection)
  end

  def bare_exec *args
    bare_connection.execute *args
  end

  def bare_transaction
    bare_exec "BEGIN"
    yield
    bare_exec "COMMIT"
  rescue => e
    bare_exec "ROLLBACK"
    raise e
  end

  def import_from path, zone
    conn, tr = User.connection.instance_variable_get(:@connection), false
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

    File.open(path, 'r') do |src|
      serial = src.gets.chomp
      if serial =~ /\A[0-9]+\Z/
        serial = serial.to_i
      else
        raise "Bad export format"
      end
      columns = src.gets.chomp.split(?,)

      if serial > zone.serial_numbers[real_model]
        bare_transaction do
          tr = true
          bare_exec "DELETE FROM #{table_name} WHERE global_id LIKE ?", "#{zone.name}/%"
          catch :end do
            get = proc { src.gets or throw(:end) }
            loop do
              keys, placeholders, values = %w(zone_id), %w(?), [zone.id]
              columns.each do |col|
                keys << col
                type, line = get.().chomp.split '',2
                value = case type
                  when ?: then eval %Q("#{line}")
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

              bare_exec(
                "INSERT INTO #{table_name} (#{keys.join(',')}) VALUES (#{placeholders.join(',')})", 
                values)
            end
          end

          # zone.serial_numbers[real_model] = serial
          sn = bare_exec(
            "SELECT id FROM serial_numbers WHERE model=? AND zone_id=?",
            [ real_model.name, zone.id ]).first
          if sn
            bare_exec(
              "UPDATE serial_numbers SET value=?,exported=? WHERE id=?",
              [ serial, 't', sn['id'] ])
          else
            bare_exec(
              "INSERT INTO serial_numbers (model,zone_id,value,exported) VALUES (?,?,?,?)",
              [ real_model.name, zone.id, serial, 't' ])
          end
        end
        bare_exec "VACUUM"
        true
      else
        false
      end
    end
  end

  def export_for path, zone
    serial = if File.exist?(path)
      File.open(path, 'r') do |f|
        f.gets.to_i # Column list will make it 0
      end
    else
      0
    end

    return false unless serial < zone.serial_numbers[real_model]

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
      out.puts zone.serial_numbers[real_model]
      columns = (column_names - [ primary_key, 'zone_id' ]).sort
      out.puts columns.join(?,)

      exportable_for(zone).find_each do |record|
        columns.each do |col|
          v = record.send col
          out.puts case v
            when true  then ?t
            when false then ?f
            when nil   then ?n
            else ?: + v.to_s.inspect[1...-1]
          end
        end
      end
    end
    zone.exported! real_model
    true
  end
end
