# encoding: utf-8

class String
  def fix!
    rstrip!
    gsub! /#.*$/, ''
    gsub! "\xC2\xA0", ' '
    present?
  end
end

puts 'Creating villages'
if Zone.count.zero?
  Zone.transaction do
    File.open('db/fixtures/zones.txt', 'r') do |f|
      idents = {}
      f.each_line do |line|
        next unless line.fix!
        ident = line.match(/^\s*/).to_s.size
        point = if line[-1] == '*'
          line[-1] = ''
          true
        else
          false
        end
        idents[ident] = Zone.create name: line.lstrip, parent: idents[ident-1], point: point
      end
    end
  end
end

=begin
unless (children_count = ENV['CHILDREN'].to_i) < 1
  puts "Creating mockup children (#{children_count} entries)"

  children_count.times do
    child = Child.create(
      first_name: Faker::Name.first_name,
      last_name:  Faker::Name.last_name,
      born_on:    rand(365*10).days.ago,
      last_visit_at:    rand(365*10).days.ago,
      gender: rand(2) == 0,
      village_id: rand(Village.count)+1)

    (rand(3)+1).times do
      Diagnostic.create(
        child: child,
        author_global_id: "#{Csps.site}/1",
        done_on: rand(365*10).days.ago)
    end
  end
end
=end

puts 'Creating illnesses'

illnesses, deps = {}, {}

File.open('db/fixtures/sign_dependencies.txt', 'r') do |f|
  f.each_line do |line|
    next unless line.fix!
    deps.store *line.split('|')
  end
end

Illness.transaction do
  File.open('db/fixtures/signs.txt', 'r') do |f|
    illness, seq = nil, 0
    f.each_line do |line|
      next unless line.fix!
      data = line.chomp.strip.split '|'
      if line =~ /\A\s/
        # Sign
        hash = {
          illness: illness,
          key: data[0],
          dep: deps["#{illness.key}.#{data[0]}"],
          question: RedCloth.new(data[1], [:lite_mode]).to_html }
        case data[2]
          when 'integer'
            hash[:min_value] = data[3]
            hash[:max_value] = data[4]
          when 'list'
            hash[:values] = data[3]
        end
        (data[2].camelize + 'Sign').constantize.create hash
      else
        # Illness
        next if data[1].blank?
        illness = Illness.create(
          key: data[0],
          name: data[1],
          sequence: seq)
        illnesses[illness.key] = illness
        seq += 1
      end
    end
  end
end

puts 'Creating treatments'

treatments = {}
File.open('db/fixtures/treatments.txt', 'r') do |f|
  cl = nil
  f.each_line do |line|
    line.gsub! %r(/\*.*?\*/), ''
    line.gsub! "\xC2\xA0", ' '
    next if line.blank?
    if line =~ /^\[(.+)\]\Z/
      cl = $1
    elsif cl
      treatments[cl] ||= ''
      treatments[cl] += line
    end
  end
end

puts 'Creating classifications'

File.open('db/fixtures/classifications.txt', 'r') do |f|
  f.each_line do |line|
    next unless line.fix!
    illness, name, equation = line.split '|'
    illnesses[illness].classifications.create!(
      name: name,
      treatment: treatments.delete(name).try(:chomp),
      equation: equation)
  end
end

if treatments.any?
  STDERR.puts "WARNING: #{treatments.size} orphaned treatments!"
  STDERR.puts "Keys: #{treatments.keys.join(', ')}."
end

puts 'Creating translations'

t = {}
File.open('db/fixtures/queries_translations.txt', 'r') do |f|
  f.each_line do |line|
    next unless line.fix!
    k, v = line.split("\t").map &:strip
    raise "Error: #{k}" if v.blank?
    t[k] = v
  end
end

puts 'Creating queries'

stats = File.read(File.join('db', 'fixtures', 'queries.txt'))
Query.destroy_all
stats.split('@').each do |s|
  next if s.blank?
  title = s.split("\n").first.strip
  source = s.split("\n")[1..-1].join("\n")
  h = JSON.parse(source)
  case_status = Query::CASE_STATUSES.index(h.delete('case_status'))
  klass = h.delete('klass')
  q = Query.new(:title => t[title], :case_status => case_status, :klass => klass, :conditions => h['conds'].to_json)
  puts "Error importing #{title}: q.errors" unless q.save
end

puts 'Creating indices'

Index.destroy_all
Index::NAMES.each do |name|
  %w(boys girls).each do |gender|
    begin
      if name == 'weight-height'
        %w(above-2y under-2y).each do |age|
          file_name = File.join('db', 'fixtures', 'indices', "#{name}-#{age}-#{gender}.txt")
          File.open(file_name, 'r') do |f|
            f.each_line do |line|
              next unless line.fix!
              x, y = line.split ','
              i = Index.new(:x => x, :y => y, :for_boys => (gender == 'boys'), :name => Index::NAMES.index(name), :above_2yrs => (age == 'above-2y'))
              puts i.errors unless i.save
            end
          end
        end
      else
        file_name = File::join('db', 'fixtures', 'indices', "#{name}-#{gender}.txt")
        File.open(file_name, 'r') do |f|
          f.each_line do |line|
            next unless line.fix!
            x, y = line.split ','
            i = Index.new(:x => x, :y => y, :for_boys => (gender == 'boys'), :name => Index::NAMES.index(name))
            puts i.errors unless i.save
          end
        end
      end
    rescue => e
      puts "Can't load #{file_name}: #{e}"
    end
  end
end
