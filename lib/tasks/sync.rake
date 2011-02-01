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
end
