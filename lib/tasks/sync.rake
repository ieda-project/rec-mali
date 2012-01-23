require 'fileutils'

def check_sync_conditions
  unless Csps.site
    STDERR.puts 'Error: Please run the app and create your site first!'
    exit 1
  end
  unless ENV['REMOTE'].present? && File.directory?(ENV['REMOTE'])
    STDERR.puts 'Error: Please specify a data directory with REMOTE'
    exit 1
  end
  @sync_at ||= Time.at Time.now.to_i # (shaving off microseconds)
end

def remote sub=''
  ENV['REMOTE'] + (sub.present? ? "/#{sub}" : '')
end

namespace :sync do
  desc 'Sync PGP keys'
  task :keys => :environment do
    check_sync_conditions
    gpg = "gpg --homedir #{Rails.root}/config/gpg"

    if `#{gpg} --list-secret-keys --with-colons` == ''
      puts "Creating secret key for #{Zone.csps.name} <csps+#{Zone.csps.hostname}@tdh.ch>"
      IO.popen("#{gpg} --batch --gen-key -", 'w') do |b|
        b.puts 'Key-Type: RSA'
        b.puts 'Key-Length: 2048'
        b.puts "Name-Real: #{Zone.csps.name}"
        b.puts "Name-Email: csps+#{Zone.csps.hostname}@tdh.ch"
        b.puts "Expire-Date: 0"
        b.close_write
      end

      puts "Exporting key"
      FileUtils.mkdir_p remote('keys')
      `#{gpg} --armor --export #{Zone.csps.name} > #{remote}/keys/#{Zone.csps.name}`
    end

    # Import ALL the keys!
    puts "Importing others' public keys"
    Dir.glob("#{remote}/keys/*") do |path|
      `#{gpg} --import #{path}`
    end

    if Zone.csps.root?
      # Export ALL the keys!
      puts "Exporting keys"
      `#{gpg} -k --with-colons`.each_line do |line|
        line = line.split ':'
        next unless line[0] == 'pub'
        n = line[9].sub(/ .*$/, '')
        `#{gpg} --armor --export #{n} > #{remote}/keys/#{n}`
      end
    end
  end

  desc 'Synchronize'
  task :perform => :keys do
    require 'fileutils'
    gpg = "gpg --homedir #{Rails.root}/config/gpg"

    begin
      check_sync_conditions
      ipzk = {}
      tmp = "#{Dir.tmpdir}/sync.#{$$}"

      FileUtils.rm_rf tmp if File.directory? tmp
      FileUtils.mkdir_p tmp

      unpack = ->(zone) do
        dir = "#{tmp}/#{zone.folder_name}"
        FileUtils.mkdir_p dir
        if File.exist? "#{remote}/#{zone.folder_name}.tgz.gpg"
          `#{gpg} --output #{tmp}/#{zone.folder_name}.tgz -d #{remote}/#{zone.folder_name}.tgz.gpg`
          unless $?.success?
            puts "#{zone.name} CANNOT BE DECRYPTED!"
            return false
          end
          `tar xzf #{tmp}/#{zone.folder_name}.tgz -C #{dir}`
          dir
        end
      end

      # IMPORTING
      p = %r|/([a-z0-9_]+)\.csps\Z|
      puts "Starting import.."
      Zone.importable_points.each do |zone|
        next unless dir = unpack.(zone)
        imported, ipzk[zone] = false, {}
        Dir.glob("#{dir}/*.csps") do |path|
          model = path.scan(p).first.first
          klass = model.camelize.constantize rescue next
          print "Importing #{klass.name} from #{zone.name}: "
          imported = true
          if Csps::SyncProxy.for(klass).import_from(path, zone)
            puts "done."
            ipzk[zone][klass] = true
          else
            puts "skipped, no change."
          end
        end
        if imported
          zone.update_attributes last_import_at: @sync_at, restoring: false
        end
      end

      # EXPORTING
      if Zone.csps.parent_id
        puts "Starting export.."
        Zone.exportable_points.each { |zone| unpack.(zone) }

        Csps::Exportable.models.each do |klass|
          proxy = Csps::SyncProxy.for klass
          Zone.exportable_points.each do |zone|
            next if (ipzk[zone] && ipzk[zone][klass]) || proxy.exportable_for(zone).empty?
            path = "#{tmp}/#{zone.folder_name}/#{klass.name.underscore}.csps"

            print "Exporting #{klass.name} for #{zone.name}: "
            if proxy.export_for path, zone
              puts "done."
            else
              puts "skipped, no change."
            end
            zone.update_attribute :last_export_at, @sync_at
          end
        end

        # PACKING UP
        keys = []
        `#{gpg} -k --with-colons`.each_line do |l|
          l = l.split ':'
          keys << l[9].sub(/ .*$/, '') if l[0] == 'pub'
        end
        Zone.exportable_points.each do |zone|
          opts = ["-r #{Zone.csps.hostname}"]
          zone.upchain.each do |z|
            opts << "-r #{z.hostname}" if keys.include? z.hostname
          end
          Dir.chdir "#{tmp}/#{zone.folder_name}" do
            `tar czf - *|#{gpg} --yes -e --output #{remote}/#{zone.folder_name}.tgz.gpg #{opts.join(' ')}`
          end
        end
      else
        puts 'No need to export at the root level.'
      end
    ensure
      FileUtils.rm_rf tmp
    end
  end
  
  desc 'Migrate database with seed if needed'
  task migrate: 'db:migrate' do
    Rake::Task['db:seed'].invoke if Illness.count.zero?
  end

  desc 'Offset timestamps in database after system clock change'
  task :offset_time => :environment do
    seconds = ENV['BY'].to_i
    unless seconds.zero?
      update = ->(table, *fields) do
        for i in fields do
          User.connection.execute "
            UPDATE #{table}
            SET #{i}=datetime(strftime('%s', #{i}) + #{seconds}, 'unixepoch')
            WHERE #{i} IS NOT NULL"
        end
        update
      end

      update.
        (:diagnostics, :created_at, :updated_at, :done_on).
        (:children, :created_at, :updated_at, :last_visit_at).
        (:illness_answers, :created_at, :updated_at).
        (:sign_answers, :created_at, :updated_at).
        (:queries, :last_run_at).
        (:zones, :last_import_at, :last_export_at)
    end
  end

  desc "Export SPSS data"
  task :spss => :environment do
    require 'csv'
    dir = ENV['TO'] || '.'
    raise "No such directory: #{dir}" unless File.directory? dir

    dir = "#{dir}/#{Zone.csps.folder_name}"
    FileUtils.mkdir_p dir

    for ref in Diagnostic.select('DISTINCT type, age_group') do
      type = ref.type.nil? ? 'base' : ref.type.sub(/Diagnostic$/, '').underscore
      File.open("#{dir}/#{type}_#{ref.age_group_key}.spss", 'w') do |out|
        children = if ref.type
          Child.where(
            'children.global_id IN (SELECT child_global_id FROM diagnostics WHERE type=? AND age_group=?)',
            ref.type, ref.age_group)
        else
          Child.where(
            'children.global_id IN (SELECT child_global_id FROM diagnostics WHERE type IS NULL AND age_group=?)',
            ref.age_group)
        end
        children = children.includes(diagnostics: { sign_answers: :sign }) #.order('signs.id') is worth nothing

        # Header
        buf = %w(born gender village bcg_polio0 penta1_polio1 penta2_polio2
          penta3_polio3 measles diag_date height weight muac temperature)
        buf += children.first.diagnostics.first.sign_answers.sort_by(&:sign_id).map do |sa|
          sa.sign.full_key
        end
        out.puts CSV.generate_line(buf)

        children.find_each do |child|
          buf = [
            child.born_on,
            child.gender ? 'm' : 'f',
            child.village.name ]
          buf += [
            child.bcg_polio0, child.penta1_polio1, child.penta2_polio2,
            child.penta3_polio3, child.measles ].map { |v| v ? 'oui' : 'non' }
          child.diagnostics.each do |diag|
            buf += [
              diag.done_on.to_date, diag.height, diag.weight,
              diag.mac, diag.temperature ]
            buf += diag.sign_answers.sort_by(&:sign_id).map(&:spss_value)
          end
          out.puts CSV.generate_line(buf)
        end
      end
    end
  end
end
