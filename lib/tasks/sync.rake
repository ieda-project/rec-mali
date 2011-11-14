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

namespace :sync do
  desc 'Synchronize'
  task :perform => :environment do
    check_sync_conditions
    ipzk = {}

    # IMPORTING
    p = %r|/([a-z0-9_]+)\.csps\Z|
    puts "Starting import.."
    Zone.importable_points.each do |zone|
      imported = false
      ipzk[zone] = {}
      Dir.glob("#{ENV['REMOTE']}/#{zone.folder_name}/*.csps") do |path|
        puts path
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

      Csps::Exportable.models.each do |klass|
        proxy = Csps::SyncProxy.for klass
        Zone.exportable_points.each do |zone|
          next if (ipzk[zone] && ipzk[zone][klass]) || proxy.exportable_for(zone).empty?
          path = "#{ENV['REMOTE']}/#{zone.folder_name}/#{klass.name.underscore}.csps"
          FileUtils.mkdir_p File.dirname(path)

          print "Exporting #{klass.name} for #{zone.name}: "
          if proxy.export_for path, zone
            puts "done."
          else
            puts "skipped, no change."
          end
          zone.update_attribute :last_export_at, @sync_at
        end
      end
    else
      puts 'No need to export at the root level.'
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
