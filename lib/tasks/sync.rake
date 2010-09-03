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
  task :perform => [ :up, :down ]

  desc 'Read remote databases'
  task :down => :environment do
    check_sync_conditions
    p = %r|/([a-z0-9_]+)\.csps\Z|
    puts "Starting import.."
    Zone.importable_points.each do |zone|
      Dir.glob("#{ENV['REMOTE']}/#{zone.folder_name}/*.csps") do |path|
        model = path.scan(p).first.first
        klass = model.camelize.constantize rescue next

        next if zone.ever_imported? and zone.last_import_at >= File.mtime(path)

        puts "Importing #{klass.name} from #{zone.name}"
        File.open(path, 'r') { |src| Csps::SyncProxy.for(klass).import_from(src, zone) }
      end
      zone.update_attribute :last_import_at, @sync_at
    end
  end

  desc 'Dump local database'
  task :up => :environment do
    check_sync_conditions
    if Zone.csps.parent_id
      # Load all models
      Dir.glob("#{Rails.root}/app/models/*.rb").each do |f|
        Object.const_get File.basename(f).sub(/\.rb\Z/, '').camelize
      end

      puts "Starting export.."

      Csps::Exportable.models.each do |klass|
        proxy = Csps::SyncProxy.for klass
        Zone.exportable_points.each do |zone|
          next if proxy.exportable_for(zone).empty?
          path = "#{ENV['REMOTE']}/#{zone.folder_name}/#{klass.name.underscore}.csps"
          FileUtils.mkdir_p File.dirname(path)

          if lastmod = klass.last_modified(zone)
            next if File.exist?(path) and lastmod <= File.mtime(path)

            puts "Exporting #{klass.name} for #{zone.name} (#{lastmod})"
            File.open(path, 'w') do |out|
              proxy.export_for out, zone
            end
            File.utime lastmod, lastmod, path
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
end
