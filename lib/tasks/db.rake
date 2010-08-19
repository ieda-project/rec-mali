namespace :db do
  desc 'db:drop + db:create + db:migrate + db:seed'
  task :recreate => ['db:drop', 'db:create', 'db:migrate', 'db:seed'] do
  end
end
