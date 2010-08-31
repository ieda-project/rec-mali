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

        lastmod = klass.last_modified zone
        next if !File.exist?(path) or (lastmod and lastmod >= File.mtime(path))

        puts "Importing #{klass.name} from #{zone.name}"
        File.open(path, 'r') { |src| klass.import_from src }
      end
    end
  end

  desc 'Dump local database'
  task :up => :environment do
    check_sync_conditions

    # Load all models
    Dir.glob("#{Rails.root}/app/models/*.rb").each do |f|
      Object.const_get File.basename(f).sub(/\.rb\Z/, '').camelize
    end

    puts "Starting export.."
    Zone.exportable_points.each do |zone|
      Csps::Exportable.models.each do |klass|
        path = "#{ENV['REMOTE']}/#{zone.folder_name}/#{klass.name.underscore}.csps"
        FileUtils.mkdir_p File.dirname(path)

        if lastmod = klass.last_modified(zone)
          next if File.exist?(path) and lastmod <= File.mtime(path)

          puts "Exporting #{klass.name} for #{zone.name} (#{lastmod})"
          File.open(path, 'w') do |out|
            klass.export_to out
          end
          File.utime lastmod, lastmod, path
        end
      end
    end
  end
  
  desc 'Migrate database with seed if needed'
  task migrate: 'db:migrate' do
    Rake::Task['db:seed'].invoke if Illness.count.zero?
  end
end
