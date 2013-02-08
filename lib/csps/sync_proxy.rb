module Csps::SyncProxy
  if `which java`.present?
    JAVA = 'java'
  elsif File.exist?('/opt/jre')
    JAVA = '/opt/jre/bin/java'
  else
    JAVA = false
  end

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

  def dbname
    dbcfg = Rails.configuration.database_configuration[Rails.env]
    dbcfg['database'] || dbcfg[:database]
  end

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

    if JAVA && connection.adapter_name == 'SQLite'
      sn = zone.serial_numbers[real_model].to_s
      bare_exec 'BEGIN TRANSACTION'
      bare_exec 'COMMIT'

      system(JAVA,
        '-classpath', 'java/sqlite3.jar:java', 'Loader',
        sn,
        dbname,
        table_name,
        real_model.name,
        zone.name,
        path)
    else
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
            bare_exec "DELETE FROM #{table_name} WHERE global_id LIKE ?", "#{zone.name}/%"
            l = 1
            catch :end do
              get = proc { l += 1; src.gets or throw(:end) }
              loop do
                keys, placeholders, values = %w(zone_id), %w(?), [zone.id]
                columns.each do |col|
                  keys << col
                  type, line = get.().chomp.split '',2
                  value = case type
                    when ?:
                      begin
                        JSON.parse(%Q(["#{line}"])).first
                      rescue => e
                        raise "#{e.message} at line #{l}"
                      end
                    when ?t, ?f then type
                    when ?n
                      placeholders << 'NULL'
                      nil
                    else
                      raise("Bad dump at line #{l}")
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

    if JAVA && connection.adapter_name == 'SQLite'
      system(JAVA,
        '-classpath', 'java/sqlite3.jar:java', 'Dumper',
        zone.serial_numbers[real_model].to_s,
        dbname,
        table_name,
        exportable_for(zone).to_sql.sub(/^.*WHERE\s+/, ''),
        path)
    else
      columns = columns_hash.map do |name,data|
        next if %w(id zone_id).include? name
        name = name.dup # unfreeze
        if data.type == :boolean
          def name.export v; (v.nil? || v == '') ? 'n' : v; end
        else
          def name.export v
            v ? ":#{v.to_s.inspect[1...-1]}" : 'n'
          end
        end
        name
      end.compact.sort

      File.open path, 'w' do |out|
        out.puts zone.serial_numbers[real_model]
        out.puts columns.join(?,)

        lastid = 0
        sql = exportable_for(zone).order('id ASC').limit(500).where('id > %ID%').to_sql
        loop do
          list = connection.execute(sql.sub('%ID%', lastid.to_s))
          break if list.empty?
          list.each do |r|
            columns.each do |col|
              out.puts col.export(r[col])
            end
          end
          lastid = list.last['id']
        end
      end
    end

    zone.exported! real_model
    true
  end
end
