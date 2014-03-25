class ReplaceGlobalId < ActiveRecord::Migration
  module Bogus; end

  def self.up
    models, fakes = Csps::Exportable.models, {}

    db = ActiveRecord::Base.connection
    raw = db.raw_connection

    case db.adapter_name
      when 'SQLite'
        sql_type = :integer
        set = "(cast((cast(strftime('%s', created_at) as real) + cast(strftime('%f', created_at) as real) - cast(strftime('%S', created_at) as real)) * 1000 as integer)-id) | (zone_id << 48)"
      when 'PostgreSQL'
        sql_type = :bigint
        set = 'round(extract(epoch from created_at) * 1000)::bigint | (zone_id::bigint << 48)'
      else raise "Non-supported adapter"
    end

    # Step 1: Add uqid columns and generate values
    puts "Generating unique IDs"
    for m in models
      puts ".. #{m.name}"
      tbl = m.table_name

      add_column tbl, :uqid, sql_type
      add_index tbl, [:uqid], unique: true
      m.reset_column_information

      # Create fake models for the same tables, and add them to our
      # Bogus module so they have names.
      mm = Class.new ActiveRecord::Base
      mm.inheritance_column = :_none
      mm.table_name = tbl
      Bogus.const_set m.name, mm
      fakes[m] = mm

      execute "UPDATE #{tbl} SET uqid=#{set}"
    end

    # Step 2: Update references
    puts "Updating global references"
    for m in models
      refs = m.global_refs
      next if refs.empty?

      puts ".. #{m.name}"
      tbl, sets, kode = m.table_name, [], []
      mm = fakes[m]

      refs.each.with_index do |ref,i|
        # Add the reference column
        add_column tbl, "#{ref}_uqid", sql_type

        # Add the references to the fake model in the OLD way
        mm.belongs_to ref,
          primary_key: :global_id,
          foreign_key: "#{ref}_global_id",
          class_name: fakes[m.reflections[ref].klass].name

        # Populate the prepared statement and the update code
        sets << "#{ref}_uqid=?"
        kode << "(r.#{ref} && r.#{ref}.uqid)"
      end

      tmpl = "UPDATE #{tbl} SET #{sets.join(',')} WHERE id=?"
      kode = kode.join ','

      case db.adapter_name
        when 'SQLite'
          stmt = raw.prepare(tmpl)
          mm.includes(*refs).find_each &eval("->(r) { stmt.execute(#{kode}, r.id) }")
        when 'PostgreSQL'
          n = "#{tbl}_update_uqid_#{$$}"

          # Turns ? placeholders into $1, $2, ... in an ugly way.
          c = 0; tmpl.gsub!('?') { "$#{c += 1}" }
          raw.prepare(n, tmpl)

          begin
            mm.includes(*refs).find_each &eval("->(r) { raw.exec_prepared('#{n}', [#{kode}, r.id]) }")
          ensure
            execute "DEALLOCATE #{n}" rescue nil
          end
      end
    end

    # Step 3: Rename child images.
    Dir.glob "#{Rails.root}/public/repo/*" do |dir|
      zone = File.basename(dir)
      Dir.chdir dir do
        Dir.glob '*_children_*' do |fn|
          gid, rest = fn.split('_', 2)
          ch = Child.where(global_id: "#{zone}/#{gid}").select(:uqid).first
          system "mv #{fn} #{ch.uqid}_#{rest}" if ch
        end
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
