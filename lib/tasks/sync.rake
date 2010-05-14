namespace :sync do
  desc 'Dump the database for syncing'
  task :dump => :environment do
    target = ENV['TARGET']
    unless target.present? && File.directory?(target)
      STDERR.puts 'Error: Please specify a target directory with TARGET'
      exit 1
    end

    unless Rails.env.production?
      # Load all models
      Dir.glob("#{Rails.root}/app/models/*.rb").each do |f|
        Object.const_get File.basename(f).sub(/\.rb\Z/, '').camelize
      end
    end

    Csps::Exportable.models.each do |model|
      puts "Exporting #{model} (#{model.local.count})"
      File.open("#{target}/#{model.name.underscore}.csps", 'w') do |out|
        columns = (model.column_names - [ model.primary_key, 'imported' ]).sort
        out.puts columns.join(',')

        model.local.order(:created_at).each do |record|
          columns.each do |col|
            v = record.send col
            out.puts case v
              when true then 't'
              when false then 'f'
              when nil then 'n'
              else ':' + v.to_s.gsub("\n", "\\\n")
            end
          end
        end
      end
    end
  end
end
