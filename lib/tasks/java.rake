namespace :java do
  desc 'Build Java dumper'
  task :build_dumper do
    Dir.chdir File.expand_path('../../../java', __FILE__) do
      system "javac Dumper.java"
      system "jar cvfe dumper.jar *.class"
      system "rm -f *.class"
    end
  end
end
