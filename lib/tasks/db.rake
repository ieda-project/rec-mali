namespace :db do
  desc 'db:drop + db:create + db:migrate + db:seed'
  task :recreate => ['db:drop', 'db:create', 'db:migrate', 'db:seed'] do
  end

  task :check_dump => :environment do
    dump = proc do |m,*lst|
      puts "[#{m.name}]"
      m.order('id ASC').each do |r|
        puts(lst.map { |c| r.send(c) }.join(' '))
      end
    end
    dump.(Classification, :id, :name)
    dump.(Sign, :id, :key)
    dump.(Prescription, :id, :treatment_id, :medicine_id, :instructions)
    dump.(Treatment, :id, :name)
  end
end
