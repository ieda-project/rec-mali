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

    list = if File.exist?(remote('export.list'))
      File.read(remote('export.list')).gsub(/#.*$/, '').split("\n").select(&:present?)
    end
    if !list || !list.include?(Zone.csps.name)
      File.open(remote('export.list'), 'a') do |f|
        f.puts Zone.csps.name
      end
      list << Zone.csps.name if list
    end
    if list && (list & Zone.csps.upchain.map(&:name)).any?
      # Export all if anybody from the upchain is looking.
      list = nil
    end

    # Export list handling over

    FileUtils.chmod '700'.to_i(8), "#{Rails.root}/config/gpg"
    gpg = "gpg --homedir #{Rails.root}/config/gpg"

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

      # Reset tempdir
      FileUtils.rm_rf "#{tmp}/*"

      keys = []
      `#{gpg} -k --with-colons`.each_line do |l|
        l = l.split ':'
        keys << l[9].sub(/ .*$/, '') if l[0] == 'pub'
      end

      # EXPORTING
      if Zone.csps.parent_id && (!list || list.any?)
        all, zones = Zone.exportable_points, []
        all = all.where('name IN (?)', list) if list

        for zone in all do
          next unless keys.include?(zone.folder_name)
          if (updated_keys & keys).any?
            puts "Forcing export of #{zone.name}, public key has changed."
            FileUtils.mkdir_p "#{tmp}/#{zone.folder_name}"
          else
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
            print "Packing and encrypting for #{zone.name}: "
            tgts = [ zone, Zone.csps, *zone.upchain ].map(&:folder_name).uniq & keys
            Dir.chdir "#{tmp}/#{zone.folder_name}" do
              `tar czf - *|#{gpg} --yes -e --output #{remote}/#{zone.folder_name}.tgz.gpg -r #{tgts.join(' -r ')}`
            end
            puts 'ok.'
          end
        else
          puts "No zones to export to."
        end
      elsif Zone.csps.parent_id
        puts "No export: list empty."
      else
        puts "No export: root level."
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

    for ref in Diagnostic.select('DISTINCT type, saved_age_group') do
      type = ref.type.nil? ? 'base' : ref.type.sub(/Diagnostic$/, '').underscore
      File.open("#{dir}/#{type}_#{Csps::Age::GROUPS[ref.saved_age_group]}.spss", 'w') do |out|
        children = if ref.type
          Child.where(
            'children.global_id IN (SELECT child_global_id FROM diagnostics WHERE type=? AND saved_age_group=?)',
            ref.type, ref.saved_age_group)
        else
          Child.where(
            'children.global_id IN (SELECT child_global_id FROM diagnostics WHERE type IS NULL AND saved_age_group=?)',
            ref.saved_age_group)
        end
        children = children.includes(diagnostics: { sign_answers: :sign }) #.order('signs.id') is worth nothing

        # Header
        buf = %w(born gender village bcg_polio0 penta1_polio1 penta2_polio2
          penta3_polio3 measles diag_date height weight muac temperature)
        buf += children.first.diagnostics.first.sign_answers.sort_by(&:sign_id).map do |sa|
          sa.sign.full_key
        end
        out.puts CSV.generate_line(buf)

        children.find_each(batch_size: 100) do |child|
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

  desc "Export Excel data"
  task :excel => :environment do
    require 'csv'
    dir = ENV['TO'] || '.'
    raise "No such directory: #{dir}" unless File.directory? dir

    dir = "#{dir}/#{Zone.csps.folder_name}"
    FileUtils.mkdir_p dir

    for ref in Diagnostic.select('DISTINCT type, saved_age_group') do
      type = ref.type.nil? ? 'base' : ref.type.sub(/Diagnostic$/, '').underscore
      File.open("#{dir}/#{type}_#{Csps::Age::GROUPS[ref.saved_age_group]}.csv", 'w') do |out|
        diags = ref.class.where(saved_age_group: ref.saved_age_group).includes(:child, sign_answers: :sign)

        # Header
        buf = %w(global_id born gender village bcg_polio0 penta1_polio1 penta2_polio2
          penta3_polio3 measles diag_date height weight muac temperature)
        buf += diags.first.sign_answers.sort_by(&:sign_id).map do |sa|
          sa.sign.full_key
        end
        out.puts CSV.generate_line(buf)

        diags.find_each(batch_size: 100) do |diag|
          child = diag.child
          buf = [
            child.global_id,
            child.born_on,
            child.gender ? 'm' : 'f',
            child.village.name ]
          buf += [
            child.bcg_polio0, child.penta1_polio1, child.penta2_polio2,
            child.penta3_polio3, child.measles ].map { |v| v ? 'oui' : 'non' }
          buf += [
            diag.done_on.to_date, diag.height, diag.weight,
            diag.mac, diag.temperature ]
          buf += diag.sign_answers.sort_by(&:sign_id).map(&:spss_value)
          out.puts CSV.generate_line(buf)
        end
      end
    end
  end
end
