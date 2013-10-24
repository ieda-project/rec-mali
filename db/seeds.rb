# encoding: utf-8
# vim: foldmethod=marker

# Helpers {{{
require 'csv'

def head msg; puts "==> #{msg}"; end
def info msg; puts "    #{msg}"; end

def die msg, file=nil, line=nil
  if file
    line = line ? " line #{line}" : ''
    raise "ERROR: #{msg} in file #{file.path}#{line}"
  else
    raise "ERROR: #{msg}"
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
      when 'PostgreSQL' then connection.execute(
        "ALTER SEQUENCE #{table_name}_#{primary_key}_seq RESTART WITH 1")
    end
  end
end
# }}}

# Zones {{{
if Zone.count > 0
  # Update
  unless Zone.csps && Zone.csps.root?
    if ENV['ZONE_PATH'] && File.exist?(fn = File.join(ENV['ZONE_PATH'], 'zone_update.txt'))
      head 'Updating villages'
      File.open(fn, 'r') do |f|
        f.each_line do |line|
          next unless line.fix!
          pname, name = line.split('/')
          die "Bad format", f unless name.present?

          pname.strip!
          name.strip!

          parent = Zone.where(point: !!pname.sub!(/\*$/, ''), name: pname)
          die "No such zone: #{pname}", f unless parent.any?

          parent = parent.sort_by(&:level).first
          die "Cannot add children to a village", f if parent.level > 2

          point = !!name.sub!(/\*$/, '')
          next if parent.children.where(name: name).any?

          parent.children.create(
            name: name,
            point: point,
            custom: true)
        end
      end
    else
      head 'No village update present (not a problem)'
    end
  end
elsif ENV['ZONE_DIR']
  # New install
  head 'Creating villages (scratch)'
  File.open(File.join(ENV['ZONE_PATH'], 'zones.txt'), 'r') do |f|
    Zone.transaction do
      indents = {}
      f.each_line do |line|
        next unless line.fix!
        indent = line.match(/^\s*/).to_s.size
        line.strip!

        indents[indent] = Zone.create(
          point: !!line.sub!(/\*$/, ''),
          name: line,
          parent: indents[indent-1],
          custom: false)
      end
    end
  end
else
  die "No stick location specified!"
end # }}}

Dir.chdir "#{Rails.root}/db/fixtures" do

  # Medicines {{{
  ImportVersion.process "medicines.txt" do |f|
    Medicine.purge

    HEAD    = 0
    UNIT    = 1
    FORMULA = 2
    state = HEAD
    name, key, unit, formula = nil
    save = proc do |no|
      if formula.present?
        # SAVE
        Medicine.create!(
          key: key, name: name, unit: unit,
          formula: formula)
      else
        die "No formula", f, no
      end
    end

    f.each_line.with_index do |line,no|
      next if line =~ /^#/
      case state
        when HEAD
          next if line.blank?
          name, key = line.scan(/^(.+)\s+\((.+)\)/).first
          die "Bad head", f, no unless key
          state = UNIT
        when UNIT
          die "Unfinished record", f, no if line.blank?
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

    ill, mac = {}, {}
    each_age_group do |agn,ag|
      mac[ag] = []
      ill[ag] = Hash.new do |h,k|
        h[k] = Illness.find_by_key_and_age_group k, ag
      end
    end

    cycle_files *fs do |f,agn,ag|
      macex = proc do |src|
        begin
          change = false
          mac[ag].each do |name,dfn|
            change = true if src.gsub!(name, dfn)
          end
        end while change
        die "Unresolved macro", f if src.include?(?@)
      end

      until_yield f do |line|
        next unless line.fix!
        if line[0] == ?@
          # Macro
          mname, msign, mdef = line.split(/\s+/, 3)
          die "Format error in macro definition", f unless msign == ?=
          mdef.strip!
          macex.(mdef)
          mac[ag] << [
            Regexp.new("#{mname}([^a-z_]|\\Z)"),
            (mdef =~ /\A\(.*\)\Z/ ? mdef : "(#{mdef})") ]
        else
          # Classification
          iname, name, level, equation = line.split '|'

          macex.(equation)
          equation.gsub! /\A\((.*)\)\Z/, '\1'

          illness = ill[ag][iname]
          illness.classifications.create!(
            age_group: ag,
            name: name,
            level: Classification::LEVELS.index(level.intern),
            equation: Csps::Formula.compile(illness, equation))
        end
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
          mand, tkey, mkey, duration, takes, desc = row
          mand = case mand
            when 'm' then true
            when 'o' then false
            else die "Illegal format: no mandatory flag", f
          end
          tre[ag][tkey].prescriptions.create!(
            medicine: medicines[mkey], mandatory: mand,
            duration: duration, takes: takes, instructions: desc.gsub('\n', "\n"))
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

      group = h.delete('group') || title

      klass = h.delete('klass')
      q = Query.new(
        :title => t[title],
        :case_status => status,
        :group_title => t[group],
        :klass => klass,
        :conditions => h['conds'].to_yaml[5..-1])
      info "Error importing #{title}: #{q.errors}" unless q.save
    end
  end # }}}

  # Indices {{{
  head "Indices"
  indices_imported = false
  for name in Index::NAMES - %w(weight-height)
    for gender in %w(boys girls)
      ImportVersion.process "indices/#{name}-#{gender}.txt" do |f|
        indices_imported = true
        info "Loading #{name} for #{gender}"
        h = {
          for_boys: gender == 'boys',
          name: Index::NAMES.index(name) }

        Index.destroy_all h
        f.each_line do |line|
          next unless line.fix!
          x, sd4neg, sd3neg, sd2neg, sd1neg, y, sd1, sd2, sd3, sd4 = line.split ','
          i = Index.new h.merge(x: x, y: y, sd4neg: sd4neg, sd3neg: sd3neg, sd2neg: sd2neg, sd1neg: sd1neg, sd1: sd1, sd2: sd2, sd3: sd3, sd4: sd4)
          info i.errors.inspect unless i.save
        end
      end
    end
  end

  for gender in %w(boys girls)
    for age in %w(above-2y under-2y)
      ImportVersion.process "indices/weight-height-#{age}-#{gender}.txt" do |f|
        indices_imported = true
        info "Loading weight-height for #{gender} #{age.sub('-', ' ')}"
        h = {
          above_2yrs: age == 'above-2y',
          for_boys: gender == 'boys',
          name: Index::NAMES.index('weight-height') }

        Index.destroy_all h
        f.each_line do |line|
          next unless line.fix!
          x, sd4neg, sd3neg, sd2neg, sd1neg, y, sd1, sd2, sd3, sd4 = line.split ','
          i = Index.new h.merge(x: x, y: y, sd4neg: sd4neg, sd3neg: sd3neg, sd2neg: sd2neg, sd1neg: sd1neg, sd1: sd1, sd2: sd2, sd3: sd3, sd4: sd4)
          info i.errors.inspect unless i.save
        end
      end
    end
  end

  info "All indices are up to date" unless indices_imported
  # }}}

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
