# encoding: utf-8
require 'fileutils'
require 'set'

namespace :sync do
  desc "Export Excel data"
  task :excel => :environment do
    require 'csv'
    dir = ENV['TO'] || '.'
    raise "No such directory: #{dir}" unless File.directory? dir

    dir = "#{dir}/#{Zone.csps.folder_name}"
    FileUtils.mkdir_p dir

    for ref in Diagnostic.select('DISTINCT type, saved_age_group') do
      type = ref.type.nil? ? 'base' : ref.type.sub(/Diagnostic$/, '').underscore
      ag = ref.saved_age_group

      File.open("#{dir}/#{type}_#{Csps::Age::GROUPS[ref.saved_age_group]}.csv", 'w') do |out|
        diags = ref.class.
          where(state: 'closed', saved_age_group: ag).
          includes(:child, :author, sign_answers: :sign)

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
          csps
          uqid born gender village
          weight_height_p height_age_p weight_age_p
          weight_height_z height_age_z weight_age_z
          followup author
          bcg_polio0 penta1_polio1 penta2_polio2
          penta3_polio3 measles diag_date height weight muac temperature)
        buf += diags.first.sign_answers.sort_by(&:sign_id).map do |sa|
          sa.sign.full_key
        end
        buf += all_cs.map(&:name)
        buf += all_meds.map(&:key)
        out.puts CSV.generate_line(buf)

        diags.find_each(batch_size: 100) do |diag|
          child = diag.child
          cs = Set.new(diag.classification_ids)
          meds = Set.new(diag.listed_prescriptions.map(&:medicine_id))

          buf = [
            Zone.csps.name,
            child.uqid, child.born_on, child.gender ? 'm' : 'f', child.village && child.village.name,
            diag.index_ratio('weight_height'), diag.index_ratio('height_age'), diag.index_ratio('weight_age'),
            diag.z_score('weight_height'), diag.z_score('height_age'), diag.z_score('weight_age'),
            diag.kind == 2 ? 1 : 0, diag.author.name ]
          buf += [
            child.bcg_polio0, child.penta1_polio1, child.penta2_polio2,
            child.penta3_polio3, child.measles ].map { |v| v ? 1 : 0 }
          buf += [
            diag.done_on.to_date, diag.height, diag.weight,
            diag.mac, diag.temperature ]
          buf += diag.sign_answers.sort_by(&:sign_id).map(&:spss_value)
          buf += all_cs.map { |c| cs.include?(c.id) ? 1 : 0 }
          buf += all_meds.map { |m| meds.include?(m.id) ? 1 : 0 }
          out.puts CSV.generate_line(buf)
          print '.'
        end
      end
    end
  end

  desc "Export SPSS data"
  task :spss => :environment do
    require 'csv'
    dir = ENV['TO'] || '.'
    raise "No such directory: #{dir}" unless File.directory? dir

    dir = "#{dir}/#{Zone.csps.folder_name}"
    FileUtils.mkdir_p dir

    for ref in Diagnostic.select('DISTINCT type, saved_age_group') do
      type = ref.type.nil? ? 'base' : ref.type.sub(/Diagnostic$/, '').underscore
      File.open("#{dir}/#{type}_#{Csps::Age::GROUPS[ref.saved_age_group]}.spss", 'w') do |out|
        children = if ref.type
          Child.where(
            'children.uqid IN (SELECT child_uqid FROM diagnostics WHERE type=? AND saved_age_group=?)',
            ref.type, ref.saved_age_group)
        else
          Child.where(
            'children.uqid IN (SELECT child_uqid FROM diagnostics WHERE type IS NULL AND saved_age_group=?)',
            ref.saved_age_group)
        end
        children = children.includes(diagnostics: { sign_answers: :sign }) #.order('signs.id') is worth nothing

        # Header
        buf = %w(born gender village bcg_polio0 penta1_polio1 penta2_polio2
          penta3_polio3 measles diag_date height weight muac temperature)
        buf += children.first.diagnostics.first.sign_answers.sort_by(&:sign_id).map do |sa|
          sa.sign.full_key
        end
        out.puts CSV.generate_line(buf)

        children.find_each(batch_size: 100) do |child|
          buf = [
            child.born_on,
            child.gender ? 'm' : 'f',
            child.village && child.village.name ]
          buf += [
            child.bcg_polio0, child.penta1_polio1, child.penta2_polio2,
            child.penta3_polio3, child.measles ].map { |v| v ? 'oui' : 'non' }
          child.diagnostics.each do |diag|
            buf += [
              diag.done_on.to_date, diag.height, diag.weight,
              diag.mac, diag.temperature ]
            buf += diag.sign_answers.sort_by(&:sign_id).map(&:spss_value)
          end
          out.puts CSV.generate_line(buf)
        end
      end
    end
  end
end
