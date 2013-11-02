# encoding: utf-8
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
  @remote = File.expand_path ENV['REMOTE']
  @sync_at ||= Time.at Time.now.to_i # (shaving off microseconds)
end

def remote sub=''
  @remote + (sub.present? ? "/#{sub}" : '')
end

namespace :sync do
  desc 'Synchronize'
  task :perform => :environment do
    check_sync_conditions
    require 'fileutils'

    # Export list handling

    list = raw_list = if File.exist?(remote('export.list'))
      File.read(remote('export.list')).gsub(/#.*$/, '').split("\n").select(&:present?)
    end
    if !list || !list.include?(Zone.csps.name)
      File.open(remote('export.list'), 'a') do |f|
        f.puts Zone.csps.name
      end

      # Do not use << here, that would update raw_list too:
      list = [ *list, Zone.csps.name ] if list
    end

    if list && (list & Zone.csps.upchain.map(&:name)).any?
      # Export all if anybody from the upchain is looking.
      list = nil
    end

    # Export list handling over

    gpgdir = "#{Rails.root}/config/gpg"
    FileUtils.chmod 0700, gpgdir unless File.symlink?(gpgdir)
    FileUtils.chmod 0600, Dir.glob("#{gpgdir}/*")
    gpg = "gpg --homedir #{gpgdir}"

    # ----------- STEP 1 -----------

    if `#{gpg} --list-secret-keys --with-colons` == ''
      puts "Creating secret key for #{Zone.csps.folder_name} <csps+#{Zone.csps.folder_name}@tdh.ch>"
      IO.popen("#{gpg} --batch --gen-key -", 'w') do |b|
        b.puts 'Key-Type: RSA'
        b.puts 'Key-Length: 2048'
        b.puts "Name-Real: #{Zone.csps.folder_name}"
        b.puts "Name-Email: csps+#{Zone.csps.folder_name}@tdh.ch"
        b.puts "Expire-Date: 0"
        b.close_write
      end
    end

    puts "Exporting key"
    FileUtils.mkdir_p remote('keys')
    `#{gpg} --armor --export #{Zone.csps.folder_name} > #{remote}/keys/#{Zone.csps.folder_name}`

    # Import ALL the keys!
    puts "Importing others' public keys"
    updated_keys = []
    Dir.glob("#{remote}/keys/*") do |path|
      kn = File.basename path
      next if kn == Zone.csps.folder_name
      res = `#{gpg} --import #{path} 2>&1`
      displayed = false
      unless res.include?('not changed')
        fpr = res.scan(/gpg: key ([0-9A-F]+)/).first.first
        `#{gpg} --list-keys --with-colons #{kn}`.each_line do |line|
          next unless line =~ /^pub:/
          u,trust,u,u,sig = line.split ':'
          next if trust.in?(%w(o - q n)) && sig.include?(fpr)
          unless displayed
            puts ".--------------------------------"
            puts "| REMOVING #{kn} (#{sig}), SIGNING NEW KEY"
            puts "|"
            puts "| If you are sure that the key has legitimately changed,"
            puts "| say yes to the following questions!"
            puts "`--------------------------------"
            displayed = true
          end
          `#{gpg} --yes --delete-key #{sig}`
        end
        name = File.basename path
        system "#{gpg} --yes --sign-key #{name}"
        updated_keys << name
      end
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

    # ----------- STEP 2 -----------

    begin
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
            puts "#{zone.name} cannot be decrypted, sync with a center please!"
            puts "#{zone.name} ne peut pas être décrypté. Synchronisez avec un District !"
            return false
          end
          `tar xzf #{tmp}/#{zone.folder_name}.tgz -C #{dir}`
          FileUtils.rm "#{tmp}/#{zone.folder_name}.tgz"
          dir
        end
      end

      # IMPORTING
      p = %r|/([a-z0-9_]+)\.csps\Z|
      puts "Starting import.."
      Zone.importable_points.each do |zone|
        next unless dir = unpack.(zone)
        imported, ipzk[zone] = [], {}
        Dir.glob("#{dir}/*.csps") do |path|
          model = path.scan(p).first.first
          klass = model.camelize.constantize rescue next
          print "Importing #{klass.name} from #{zone.name}: "
          imported << klass
          if Csps::SyncProxy.for(klass).import_from(path, zone)
            puts "done."
            ipzk[zone][klass] = true
          else
            puts "skipped, no change."
          end
        end

        if imported.any?
          zone.update_attributes last_import_at: @sync_at, restoring: false
        end
      end

      # Reset tempdir
      FileUtils.rm_rf "#{tmp}/*"

      keys = []
      `#{gpg} -k --with-colons`.each_line do |l|
        l = l.split ':'
        keys << l[9].sub(/ .*$/, '') if %w(pub uid).include? l[0]
      end
      keys.uniq!

      # EXPORTING
      if !list || list.any?
        all, zones = Zone.exportable_points, []
        all = all.where('name IN (?)', list) if list

        for zone in all do
          next unless keys.include?(zone.folder_name)
          if (updated_keys & keys).any?
            puts "Forcing export of #{zone.name}, public key has changed."
            FileUtils.mkdir_p "#{tmp}/#{zone.folder_name}"
          elsif raw_list && zone != Zone.csps && raw_list.include?(zone.name) && !File.exist?("#{remote}/#{zone.folder_name}.tgz.gpg")
            puts "Forcing export of #{zone.name}, data file is not present."
            FileUtils.mkdir_p "#{tmp}/#{zone.folder_name}"
          else
            puts "Unpacking for #{zone.name}"
            unpack.(zone)
          end
          zones << zone
        end

        if zones.any?
          puts "Starting export.."
          exported = {}
          Csps::Exportable.models.each do |klass|
            proxy = Csps::SyncProxy.for klass
            zones.each do |zone|
              next if (ipzk[zone] && ipzk[zone][klass]) || proxy.exportable_for(zone).empty?
              path = "#{tmp}/#{zone.folder_name}/#{klass.name.underscore}.csps"

              print "Exporting #{klass.name} for #{zone.name}: "
              if proxy.export_for path, zone
                exported[zone] = true
                puts "done."
              else
                puts "skipped, no change."
              end
              zone.update_attribute :last_export_at, @sync_at
            end
          end

          puts "Nothing to export." if exported.empty?

          # PACKING UP
          exported.keys.each do |zone|
            tgts = [ zone, Zone.csps, *zone.upchain ].map(&:folder_name).uniq & keys
            print "Packing and encrypting targets #{tgts.join(', ')}: "
            Dir.chdir "#{tmp}/#{zone.folder_name}" do
              `tar czf - *|#{gpg} --yes -e --output #{remote}/#{zone.folder_name}.tgz.gpg -r #{tgts.join(' -r ')}`
            end
            puts 'ok.'
          end
        else
          puts "No zones to export to."
        end
      else
        puts "No export: list empty."
      end

      # EXPORTING ZONES (root only)
      if Zone.csps && Zone.csps.root?
        outf = remote('zone_update.txt')
        zones = Zone.custom

        if zones.any?
          puts "Exporting custom zones"
          File.open(outf, 'w') do |f|
            zones.includes(:parent).each do |zone|
              f.puts "#{zone.parent.tagged_name}/#{zone.tagged_name}"
            end
          end
          zones.update_all exported_at: Time.now
        else
          FileUtils.rm_f outf
        end
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
end
