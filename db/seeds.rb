#User.create first_name: 'Albert', last_name: 'Schweitzer', login: 'albert'

if Village.count.zero?
  for n in %w(Kiembara Kongoussi Bobo-Dioulasso Niangoloko).map do
    Village.create name: n
  end
end

unless (children_count = ENV['CHILDREN'].to_i) < 1
  puts "Creating mockup children (#{children_count} entries)"

  children_count.times do
    child = Child.create(
      first_name: Faker::Name.first_name,
      last_name:  Faker::Name.last_name,
      born_on:    Date.parse('1999-08-11')+rand(1500),
      village_id: rand(4)+1)

    date = Date.parse('2010-05-05')
    (rand(5)+3).times do
      Diagnostic.create(
        child: child,
        author_id: 1,
        done_on: date)
      date += 1
    end
  end
end

illnesses = {}

puts 'Creating illnesses'

Illness.transaction do
  File.open('db/fixtures/signs.txt', 'r') do |f|
    illness, seq = nil, 0
    f.each_line do |line|
      line.gsub! /#.*$/, ''
      next if line.blank?
      data = line.chomp.strip.split '|'
      if line =~ /\A\s/
        # Sign
        hash = {
          illness: illness,
          key: data[0],
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
    line.gsub(%r(/\*.*?\*/), '')
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
    line.gsub! /#.*$/, ''
    next if line.blank?
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
File::open('db/fixtures/queries_translations.txt', 'r') do |f|
  while s = f.gets
    next if s.blank?
    k, v = s.split("\t").map {|x| x.strip}
    raise "error: #{k}" if v.blank?
    t[k] = v
  end
end

puts 'Creating queries'

stats = File::read(File::join('db', 'fixtures', 'queries.txt'))
Query.destroy_all
stats.split('@').each do |s|
  next if s.size == 0
  title = s.split("\n").first.strip
  source = s.split("\n")[1..-1].join("\n")
  h = JSON.parse(source)
  case_status = Query::CASE_STATUSES.index(h.delete('case_status'))
  klass = h.delete('klass')
  q = Query.new(:title => t[title], :case_status => case_status, :klass => klass, :conditions => h['conds'].to_json)
  puts "error importing #{title}: q.errors" unless q.save
end

puts 'Creating indices'

Index.destroy_all
Index::NAMES.each do |name|
  %w(boys girls).each do |gender|
    begin
      file_name = File::join('db', 'fixtures', 'indices', "#{name}-#{gender}.txt")
      File.open(file_name, 'r') do |f|
        f.each_line do |line|
          next if line.blank?
          x, y = line.split ','
          i = Index.new(:x => x, :y => y, :for_boys => (gender == 'boys'), :name => Index::NAMES.index(name))
          puts i.errors unless i.save
        end
      end
    rescue => e
      puts "Can't load #{file_name}: #{e}"
    end
  end
end
