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

Illness.transaction do
  skip = Zone.count
  if skip.zero?
    puts '==> Creating villages'
  else
    puts '==> Adding new villages if needed'
  end

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

      name, parent = line.lstrip, idents[ident-1]
      if skip > 0
        idents[ident] = Zone.where(name: name, parent_id: parent && parent.id).first or raise "Corrupt zone import file!"
        skip -= 1
      else
        idents[ident] = Zone.create name: name, parent: parent, point: point
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

  unless Medicine.count > 0
    puts '==> Creating medicines'

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
  end

  has_treatments = Treatment.count > 0
  illnesses = {}
  for group in %w(child newborn infant) do
    puts "==> Checking age group: #{group}"

    ag = Csps::Age[group]
    unless Classification.where(age_group: ag).any?
      deps = {}

      puts '    Loading sign deps'

      File.open("db/fixtures/#{group}/sign_dependencies.txt", 'r') do |f|
        f.each_line do |line|
          next unless line.fix!
          deps.store *line.split('|', 2)
        end
      end

      puts '    Creating signs'

      File.open("db/fixtures/#{group}/signs.txt", 'r') do |f|
        illness, seq = nil, 0
        f.each_line do |line|
          next unless line.fix!
          data = line.chomp.strip.split '|'
          if line =~ /\A\s/
            # Sign
            type, *mods = data[2].split(':')
            hash = {
              age_group: ag,
              illness: illness,
              key: data[0],
              dep: deps["#{illness.key}.#{data[0]}"],
              negative: mods.include?('neg'),
              question: RedCloth.new(data[1], [:lite_mode]).to_html }
            case type
              when 'integer'
                hash[:min_value] = data[3]
                hash[:max_value] = data[4]
              when 'list'
                hash[:values] = data[3]
            end
            (type.camelize + 'Sign').constantize.create hash
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

      puts '    Creating classifications'

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
    end

    next if has_treatments

    # IFFED END

    puts '    Adding auto'

    if File.exist?("db/fixtures/#{group}/auto.txt")
      File.open("db/fixtures/#{group}/auto.txt", 'r') do |f|
        sign = nil
        f.each_line do |line|
          if line.blank?
            sign.save!
            sign = nil
            next
          end
          line.strip!
          if sign
            key, code = line.split /:\s*/
            if sign.is_a? BooleanSign
              case key
                when 'true' then key = true
                when 'false' then key = false
                else next
              end
            end
            (sign.auto ||= {}).store key, code
          else
            i, s = line.split '.'
            i = illnesses[i] || Illness.find_by_key(i)
            raise "No illness: #{i}" unless i
            sign = i.signs.find_by_key_and_age_group(s, ag) or raise "No sign: #{i.key}.#{s}"
          end
        end
        sign.save! if sign
      end
    end

    puts '    Creating treatments'

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

    puts '    Creating prescriptions'

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

  unless TreatmentHelp.count > 0
    puts '==> Creating treatment help'

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
  end

  unless Query.count > 0
    puts '==> Loading translations'

    t = {}
    File.open('db/fixtures/queries_translations.txt', 'r') do |f|
      f.each_line do |line|
        next unless line.fix!
        k, v = line.split("\t").map &:strip
        raise "Error: #{k}" if v.blank?
        t[k] = v
      end
    end

    puts '==> Creating queries'

    stats = File.read(File.join('db', 'fixtures', 'queries.txt'))
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
  end

  unless Index.count > 0
    puts '==> Creating indices'

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
