# encoding: utf-8
require 'fileutils'
require 'set'

def export_age_group out, ag, diag_sep # {{{
  newline = (diag_sep == "\n")
  @sign_cache ||= ListSign.all.hashize(&:id)

  all_cs = Classification.where(age_group: ag)
  all_meds = Set.new
  all_cs.each do |i|
    i.treatments.each do |t|
      t.prescriptions.each { |p| all_meds << p.medicine }
    end
  end
  all_meds = all_meds.to_a

  # Header
  buf = %w(
    csps uqid born gender village
    distance
    weight_height_p height_age_p weight_age_p
    weight_height_z height_age_z weight_age_z
    followup number last author)
  buf += Child::VACCINATIONS.keys
  buf += %w(diag_date height weight muac temperature)
  buf += Diagnostic.where(state: 'closed', saved_age_group: ag).first.sign_answers.sort_by(&:sign_id).map do |sa|
    sa.sign.full_key
  end
  buf += all_cs.map(&:name)
  buf += all_meds.map(&:key)
  out.puts CSV.generate_line(buf)

  children = Child.where('uqid IN (SELECT DISTINCT child_uqid FROM diagnostics WHERE saved_age_group=? AND state=?)', ag, 'closed')
  children.find_each do |child|
    rel = child.diagnostics.where(saved_age_group: ag, state: 'closed')
    count = rel.count

    rel.each.with_index do |diag,num|
      num += 1
      last = (count == num)

      if num == 1 || newline
        # Spit out child
        out.print(
          CSV.generate_line([
            Zone.csps.name, child.uqid, child.born_on,
            child.gender ? 1 : 2, child.village && child.village.name ]).chomp)
        out.print ?,
      end

      # Diagnostics
      cs = Set.new(diag.classification_ids)
      meds = Set.new(diag.listed_prescriptions.map(&:medicine_id))

      buf = [
        diag.distance_name,
        diag.index_ratio('weight_height'), diag.index_ratio('height_age'), diag.index_ratio('weight_age'),
        diag.z_score('weight_height'), diag.z_score('height_age'), diag.z_score('weight_age'),
        diag.kind == 2 ? 1 : 0, num, last ? 1 : 0,
        diag.author.name ]
      buf += Child::VACCINATIONS.keys.map do |k|
        case child.send(k)
          when true then '1'
          when false then '0'
          else ''
        end
      end
      buf += [
        diag.done_on.to_date, diag.height, diag.weight,
        diag.mac, diag.temperature ]
      buf += diag.sign_answers.sort_by(&:sign_id).map do |sa|
        sa.sign = @sign_cache[sa.sign_id] if sa.is_a?(SignListAnswer)
        sa.spss_value
      end
      buf += all_cs.map { |c| cs.include?(c.id) ? 1 : 0 }
      buf += all_meds.map { |m| meds.include?(m.id) ? 1 : 0 }

      out.print CSV.generate_line(buf).chomp
      if newline || last
        out.puts
      elsif !last
        out.print ?,
      end

      print(num == 1 ? ?o : ?.)
    end
  end
  puts
end
# }}}

def export_children ext, diag_sep # {{{
  require 'csv'
  dir = ENV['TO'] || '.'
  raise "No such directory: #{dir}" unless File.directory? dir

  dir = "#{dir}/#{Zone.csps.folder_name}"
  FileUtils.mkdir_p dir

  for ref in Diagnostic.select('DISTINCT saved_age_group') do
    ag = ref.saved_age_group
    agn = Csps::Age::GROUPS[ag]

    puts "Age group: #{agn}"
    File.open("#{dir}/base_#{agn}.#{ext}", 'w') do |out|
      export_age_group out, ag, diag_sep
    end
  end
end
# }}}

namespace :sync do
  desc "Export Excel data"
  task :excel => :environment do
    export_children 'csv', "\n"
  end

  desc "Export SPSS data"
  task :spss => :environment do
    export_children 'spss', ?,
  end
end
