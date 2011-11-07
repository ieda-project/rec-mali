# encoding: utf-8

require 'csv'

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
        author_global_id: "#{Csps.site.name}/1",
        done_on: rand(365*10).days.ago)
    end
  end
end
=end

HEAD = 0
UNIT = 1
FORMULA = 2

puts 'Creating medicines'
File.open('db/fixtures/medicines.txt', 'r') do |f|
  state = HEAD
  name, key, unit, formula = nil
  brk = proc do |msg,line|
    raise "#{msg} in medicine import, #{line ? %Q(line #{line}) : 'EOF'}}"
  end
  save = proc do |no|
    if formula.present?
      # SAVE
      Medicine.create!(
        key: key, name: name, unit: unit,
        formula: formula)
    else
      brk.("No formula", no)
    end
  end

  f.each_line.with_index do |line,no|
    next if line =~ /^#/
    case state
      when HEAD
        next if line.blank?
        name, key = line.scan(/^(.+)\s+\((.+)\)/).first
        brk.("Bad head", no) unless key
        state = UNIT
      when UNIT
        brk.("Unfinished record", no) if line.blank?
        unit = line.chomp
        state, formula = FORMULA, []
      when FORMULA
        if line.blank?
          save.(no)
          state = HEAD
        else
          formula << line.split(/\s+/)
        end
    end
  end
  save.() unless state == HEAD
end

illnesses = {}
for group in %w(newborn infant child) do
  puts "==> Age group: #{group}"

  ag = Diagnostic::AGE_GROUPS.index group
  if Classification.where(age_group: ag).any?
    puts 'Skipping!'
    next
  end
  deps = {}

  puts 'Creating illnesses'

  File.open("db/fixtures/#{group}/sign_dependencies.txt", 'r') do |f|
    f.each_line do |line|
      next unless line.fix!
      deps.store *line.split('|', 2)
    end
  end

  Illness.transaction do
    File.open("db/fixtures/#{group}/signs.txt", 'r') do |f|
      illness, seq = nil, 0
      f.each_line do |line|
        next unless line.fix!
        data = line.chomp.strip.split '|'
        if line =~ /\A\s/
          # Sign
          hash = {
            age_group: ag,
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

  puts 'Creating classifications'

  File.open("db/fixtures/#{group}/classifications.txt", 'r') do |f|
    f.each_line do |line|
      next unless line.fix!
      illness, name, level, equation = line.split '|'
      begin
        illnesses[illness].classifications.create!(
          age_group: ag,
          name: name,
          level: Classification::LEVELS.index(level.intern),
          equation: Csps::Formula.compile(illness, equation))
      rescue => e
        puts "ERROR: #{group} #{name}"
      end
    end
  end

  puts 'Creating treatments'

  treatments = {}
  File.open("db/fixtures/#{group}/treatments.csv", 'r') do |f|
    f.each_line do |line|
      next if line =~ /^#/ || line.blank?
      CSV.parse line do |row|
        treatments[row.first] = Treatment.create!(
          name: row[1],
          classification: Classification.find_by_name_and_age_group(
            row[2], ag),
          description: row[3] && row[3].gsub('\n', "\n"))
      end
    end
  end

  puts 'Creating prescriptions'
  File.open("db/fixtures/#{group}/prescriptions.csv", 'r') do |f|
    f.each_line do |line|
      line.gsub! /#.*$/, ''
      next if line.blank?
      CSV.parse line do |row|
        treatments[row.first].prescriptions.create!(
          medicine: Medicine.find_by_key(row[1]),
          duration: row[2], takes: row[3], instructions: row[4].gsub('\n', "\n"))
      end
    end
  end
end

puts 'Creating treatment help'

File.open('db/fixtures/help.csv', 'r') do |f|
  f.each_line do |line|
    next if line.blank? || line =~ /^#/
    CSV.parse line do |row|
      TreatmentHelp.create!(
        key: row[0],
        title: row[1],
        image: File.exist?("public/images/help/#{row[0]}.jpg"),
        content: row[2].gsub('\n', "\n"))
    end
  end
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

if ENV['OCCUPY']
  name = ENV['OCCUPY'].gsub '_', ' '
  zones = Zone.find_all_by_name(name)
  if zone = zones[0]
    puts "Occupying #{zone.name} (##{zone.id})"
    zone.occupy!
  else
    STDERR.puts "No zone called '#{name}', please occupy by hand."
  end
end
