def check_sync_remote
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
    check_sync_remote
    p = %r|/([a-z0-9_-]+)/([a-z0-9_]+)\.csps\Z|
    Dir.glob("#{ENV['REMOTE']}/*/*.csps") do |path|
      host, model = path.scan(p).first
      next if host == Csps.site
      klass = model.camelize.constantize rescue next
      puts "Importing #{model}"
      File.open(path, 'r') { |src| klass.import_from src }
    end
  end

  desc 'Dump local database'
  task :up => :environment do
    check_sync_remote
    target = File.join ENV['REMOTE'], Csps.site

    # Load all models
    Dir.glob("#{Rails.root}/app/models/*.rb").each do |f|
      Object.const_get File.basename(f).sub(/\.rb\Z/, '').camelize
    end

    Csps::Exportable.models.each do |model|
      puts "Exporting #{model} (#{model.local.count})"
      File.open("#{target}/#{model.name.underscore}.csps", 'w') do |out|
        model.export_to out
      end
    end
  end
  
  desc 'Migrate database with seed if needed'
  task migrate: 'db:migrate' do
    Rake::Task['db:seed'].invoke if Illness.count.zero?
  end
end
