# encoding: utf-8
# vim: foldmethod=marker

# Helpers {{{
require 'csv'

def head msg; puts "==> #{msg}"; end
def info msg; puts "    #{msg}"; end

module Enumerable
  def mapcat
    reduce [] { |m,i| m + yield(i) }
  end
end

# Legacy, don't change this one!
GROUPS = %w(child newborn infant)

def all_three *fns
  GROUPS.mapcat do |g|
    fns.map { |fn| "#{g}/#{fn}" }
  end
end

def each_age_group &blk
  Enumerator.new do |y|
    GROUPS.each do |agn|
      info "For #{agn}"
      y.yield agn, Csps::Age[agn]
    end
  end.each &blk
end

def cycle_files *fs
  until fs.all?(&:eof?)
    fs.each.with_index do |f,i|
      next if f.eof?
      agn = GROUPS[i]
      yield f, agn, Csps::Age[agn]
    end
  end
end

def until_yield f
  f.each_line do |line|
    line = line.chomp
    break if line == 'yield'
    yield line
  end
end

class String
  def fix!
    rstrip!
    gsub! /#.*$/, ''
    gsub! "\xC2\xA0", ' '
    present?
  end
end

class ActiveRecord::Base
  def self.purge
    destroy_all
    case connection.adapter_name
      when 'SQLite' then connection.execute(
        "DELETE FROM sqlite_sequence WHERE name='#{table_name}'")
      when 'PostgreSQL' then connection-execute(
        "ALTER SEQUENCE #{table_name}_#{primary_key}_seq RESTART WITH 1")
    end
  end
end
# }}}

Dir.chdir "#{Rails.root}/db/fixtures" do

  # Zones {{{
  ImportVersion.process "zones.txt" do |f|
    head 'Creating villages'
    if csps = Zone.csps
      rest = csps.restoring
      csps = csps.name
    end
    Zone.purge

    indents = {}
    f.each_line do |line|
      next unless line.fix!
      indent = line.match(/^\s*/).to_s.size
      point = if line[-1] == '*'
        line[-1] = ''
        true
      else
        false
      end

      n = line.lstrip
      indents[indent] = Zone.create(
        name: n,
        parent: indents[indent-1],
        point: point)
    end
    Zone.where(name: csps).sort_by(&:level).first.occupy!(rest) if csps
  end # }}}

  # Medicines {{{
  ImportVersion.process "medicines.txt" do |f|
    Medicine.purge

    HEAD    = 0
    UNIT    = 1
    FORMULA = 2
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
  end # }}}

  # Signs {{{
  ImportVersion.process *all_three('sign_dependencies.txt', 'signs.txt') do |f1,s1,f2,s2,f3,s3|
    head "Loading illnesses and signs"
    Illness.purge
    Sign.purge

    deps, seqs = {}, {}
    [f1,f2,f3].tap do |dfiles|
      each_age_group do |agn,ag|
        seqs[ag] = 0
        deps[ag] = h = {}
        dfiles.shift.each_line do |line|
          next unless line.fix!
          h.store *line.split('|', 2)
        end
      end
    end

    cycle_files s1, s2, s3 do |f,agn,ag|
      illness = nil

      until_yield f do |line|
        next unless line.fix!
        data = line.strip.split '|'
        if line =~ /\A\s/
          # Sign
          type, *mods = data[2].split(':')
          hash = {
            age_group: ag,
            illness: illness,
            key: data[0],
            dep: deps[ag]["#{illness.key}.#{data[0]}"],
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
          next if illness = Illness.find_by_age_group_and_key(ag, data[0])
          illness = Illness.create(
            age_group: ag,
            key: data[0],
            name: data[1],
            sequence: seqs[ag])
          seqs[ag] += 1
        end
      end
    end
  end # }}}

  # Classifications {{{
  ImportVersion.process *all_three('classifications.txt') do |*fs|
    head "Loading classifications"
    Classification.purge

    ill = {}
    each_age_group do |agn,ag|
      ill[ag] = Hash.new do |h,k|
        h[k] = Illness.find_by_key_and_age_group k, ag
      end
    end

    cycle_files *fs do |f,agn,ag|
      until_yield f do |line|
        next unless line.fix!
        iname, name, level, equation = line.split '|'
        illness = ill[ag][iname]
        illness.classifications.create!(
          age_group: ag,
          name: name,
          level: Classification::LEVELS.index(level.intern),
          equation: Csps::Formula.compile(illness, equation))
      end
    end
  end # }}}

  # Treatments {{{
  ImportVersion.process *all_three('treatments.csv') do |*fs|
    head "Loading treatments"
    Treatment.purge

    cla = {}
    each_age_group do |agn,ag|
      cla[ag] = Hash.new do |h,k|
        h[k] = Classification.find_by_name_and_age_group k, ag
      end
    end

    cycle_files *fs do |f,agn,ag|
      until_yield f do |line|
        next if line =~ /^#/ || line.blank?
        CSV.parse line do |row|
          Treatment.create!(
            key: row[0], name: row[1],
            classification: cla[ag][row[2]],
            description: row[3] && row[3].gsub('\n', "\n"))
        end
      end
    end
  end # }}}

  # Prescriptions {{{
  ImportVersion.process *all_three('prescriptions.csv') do |*fs|
    Prescription.purge
    head "Loading prescriptions"

    medicines = Hash.new do |h,k|
      h[k] = Medicine.find_by_key k
    end

    tre = {}
    each_age_group do |agn,ag|
      tre[ag] = Hash.new do |h,k|
        h[k] = Treatment.
          includes(:classification).
          where('treatments.key = ? AND classifications.age_group = ?', k, ag).
          first or raise "No such treatment: #{k} for #{agn}"
      end
    end

    cycle_files *fs do |f,agn,ag|
      until_yield f do |line|
        line.gsub! /#.*$/, ''
        next if line.blank?
        CSV.parse line do |row|
          tre[ag][row.first].prescriptions.create!(
            medicine: medicines[row[1]],
            duration: row[2], takes: row[3], instructions: row[4].gsub('\n', "\n"))
        end
      end
    end
  end # }}}

  # Auto {{{
  ImportVersion.process *all_three('auto.txt') do |*fs|
    head "Loading auto"

    each_age_group.with_index do |(agn,ag),idx|
      illnesses = Hash.new do |h,k|
        h[k] = Illness.find_by_key_and_age_group k, ag
      end

      sign = nil
      fs[idx].each_line do |line|
        if line.blank?
          if sign
            sign.save!
            sign = nil
          end
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
          i = illnesses[i]
          raise "No illness: #{i}" unless i
          sign = i.signs.find_by_key_and_age_group(s, ag) or raise "No sign: #{i.key}.#{s}"
        end
      end
      sign.save! if sign
    end
  end # }}}

  # Help {{{
  ImportVersion.process "help.csv" do |f|
    TreatmentHelp.purge

    f.each_line do |line|
      next if line.blank? || line =~ /^#/
      CSV.parse line do |row|
        TreatmentHelp.create!(
          key: row[0],
          title: row[1],
          image: File.exist?("#{Rails.root}/public/images/help/#{row[0]}.jpg"),
          content: row[2].gsub('\n', "\n"))
      end
    end
  end # }}}

  # Queries {{{
  ImportVersion.process "queries_translations.txt", "queries.txt" do |tf,f|
    head "Loading queries"
    Query.purge

    t = {}
    tf.each_line do |line|
      next unless line.fix!
      k, v = line.split("\t").map &:strip
      raise "Error: #{k}" if v.blank?
      t[k] = v
    end

    stats = f.read
    stats.split('@').each do |s|
      next if s.blank?
      title = s.split("\n").first.strip
      source = s.split("\n")[1..-1].join("\n")
      h = JSON.parse(source)

      # Nil is allowed
      status = h.delete 'case_status'
      status = Query::CASE_STATUSES.index(status) if status

      klass = h.delete('klass')
      q = Query.new(
        :title => t[title],
        :case_status => status,
        :klass => klass,
        :conditions => h['conds'].to_json)
      info "Error importing #{title}: q.errors" unless q.save
    end
  end # }}}

  # Indices {{{
  head "Indices"
  for name in Index::NAMES - %w(weight-height)
    for gender in %w(boys girls)
      ImportVersion.process "indices/#{name}-#{gender}.txt" do |f|
        info "Loading #{name} for #{gender}"
        h = {
          for_boys: gender == 'boys',
          name: Index::NAMES.index(name) }

        Index.destroy_all h
        f.each_line do |line|
          next unless line.fix!
          x, y = line.split ','
          i = Index.new h.merge(x: x, y: y)
          info i.errors.inspect unless i.save
        end
      end
    end
  end

  for gender in %w(boys girls)
    for age in %w(above-2y under-2y)
      ImportVersion.process "indices/weight-height-#{age}-#{gender}.txt" do |f|
        info "Loading weight-height for #{gender} #{age.sub('-', ' ')}"
        h = {
          above_2yrs: age == 'above-2y',
          for_boys: gender == 'boys',
          name: Index::NAMES.index('weight-height') }
        f.each_line do |line|
          next unless line.fix!
          x, y = line.split ','
          i = Index.new h.merge(x: x, y: y)
          info i.errors.inspect unless i.save
        end
      end
    end
  end # }}}

end

# Occupy {{{
if ENV['OCCUPY']
  name = ENV['OCCUPY'].gsub '_', ' '
  if zone = Zone.where(name: name).sort_by(&:level).first
    head "Occupying #{zone.name} (##{zone.id})"
    zone.occupy!
  else
    STDERR.puts "No zone called '#{name}', please occupy by hand."
  end
end # }}}
