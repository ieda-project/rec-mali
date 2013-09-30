require 'stringio'

class RemoveGidColumns < ActiveRecord::Migration
  class << self
    def up
      @db = ActiveRecord::Base.connection
      send @db.adapter_name.downcase
    end

    def down
      raise ActiveRecord::IrreversibleMigration
    end

    protected

    def sqlite
      meta = Class.new ActiveRecord::Base
      meta.table_name = 'sqlite_master'
      meta.inheritance_column = :bogus

      for m in Csps::Exportable.models
        tbl = m.table_name
        cols = m.column_names.reject { |i| i =~ /global_id/ }.join(',')

        # Let's dump the database before we do anything to it
        old_dump = ruby_schema(tbl)

        # Drop the indices: the next ALTER TABLE command does not rename them,
        # so we'd get a name clash when running the dump.
        meta.where(type: 'index', tbl_name: tbl).each do |idx|
          execute "DROP INDEX #{idx.name}"
        end

        # Rename the table
        execute "ALTER TABLE #{tbl} RENAME TO old_#{tbl}"

        # Edit the dump
        dump = StringIO.new
        old_dump.each_line do |line|
          case line
            when /illness_global_id/, /add_index.*\["global_id"\]/ then next
            when /add_index.*global_id/ then line.gsub!('global_id', 'uqid')
            when /global_id/ then next
          end
          dump.puts line
        end
        eval dump.string

        # Copy over the old table to the new one
        execute "INSERT INTO #{tbl} (#{cols}) SELECT #{cols} FROM old_#{tbl}"

        # Get rid of the old one
        execute "DROP TABLE old_#{tbl}"

        # For future migrations
        m.reset_column_information
      end
    end

    def postgresql
      for m in Csps::Exportable.models
        tbl = m.table_name

        # Add the same indices to uqid
        ruby_schema(tbl).each_line do |line|
          eval line.gsub('global_id', 'uqid') if line =~ /add_index.*global_id/ && !line.include?('illness_global_id')
        end

        # Get rid of global_id columns
        # Do not replace the order of these two ops!
        m.column_names.each do |col|
          remove_column tbl, col if col =~ /global_id/
        end
      end
    end

    def ruby_schema tbl
      ActiveRecord::SchemaDumper.send(:new, @db).send(:table, tbl, StringIO.new).tap do |sio|
        sio.rewind
      end
    end
  end
end
