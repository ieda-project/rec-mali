#User.create first_name: 'Albert', last_name: 'Schweitzer', login: 'albert'

for n in %w(Kiembara Kongoussi Bobo-Dioulasso Niangoloko).map do
  Village.create name: n
end

=begin
100.times do
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
=end

illnesses = {}

Illness.transaction do
  File.open('db/fixtures/signs.txt', 'r') do |f|
    illness, seq = nil, 0
    f.each_line do |line|
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

File.open('db/fixtures/classifications.txt', 'r') do |f|
  f.each_line do |line|
    next if line.blank?
    illness, name, equation = line.split '|'
    illnesses[illness].classifications.create!(
      name: name,
      treatment: treatments.delete(name).try(:chomp),
      equation: equation)
  end
end

t = {}
File::open('db/fixtures/queries_translations.txt', 'r') do |f|
  while s = f.gets
    k, v = s.split("\t").map {|x| x.strip}
    raise "error: #{k}" if v.blank?
    t[k] = v
  end
end

stats = File::read(File::join('db', 'fixtures', 'queries.txt'))
Query.destroy_all
stats.split('@').each do |s|
  next if s.size == 0
  title = s.split("\n").first.strip
  source = s.split("\n")[1..-1].join("\n")
  h = JSON.parse(source)
  case_status = Query::CASE_STATUSES.index(h.delete('case_status'))
  klass = h.delete('klass')
  puts title
  q = Query.new(:title => t[title], :case_status => case_status, :klass => klass, :conditions => h.to_json)
  puts q.errors.inspect unless q.save
end


if treatments.any?
  puts "WARNING: #{treatments.size} orphaned treatments!"
  puts "Keys: #{treatments.keys.join(', ')}."
end
