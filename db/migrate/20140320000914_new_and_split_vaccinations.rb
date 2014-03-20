require 'stringio'

class NewAndSplitVaccinations < ActiveRecord::Migration
  SPLITS = {
    'bcg_polio0'    => %w(v_bcg v_polio0),
    'penta1_polio1' => %w(v_penta1 v_polio1),
    'penta2_polio2' => %w(v_penta2 v_polio2),
    'penta3_polio3' => %w(v_penta3 v_polio3),
  }

  RENAMES = { 'measles' => 'v_measles' }

  NEW = %w(v_meningitis v_rota v_measles_r16)

  class << self
    def up
      for col in (NEW + SPLITS.values.flatten)
        add_column :children, col, :boolean
      end

      sets = []
      SPLITS.each do |from, to|
        to.each do |i|
          sets << "#{i}=#{from}"
        end
      end

      send Child.connection.adapter_name.downcase, sets

      Child.reset_column_information
    end

    def down
      raise ActiveRecord::IrreversibleMigration
    end

    protected

    def postgresql sets
      execute "UPDATE children SET #{sets.join(',')}"

      RENAMES.each do |from, to|
        execute "ALTER TABLE children RENAME COLUMN #{from} TO #{to}"
      end

      SPLITS.keys.each { |i| remove_column :children, i }
    end

    def sqlite sets
      RENAMES.each do |from, to|
        add_column :children, to, :boolean
        sets << "#{to}=#{from}"
      end
      execute "UPDATE children SET #{sets.join(',')}"

      meta = Class.new ActiveRecord::Base
      meta.table_name = 'sqlite_master'
      meta.inheritance_column = :bogus

      Child.reset_column_information
      cols = (Child.column_names - RENAMES.keys - SPLITS.keys).join(',')
      old = ruby_schema

      meta.where(type: 'index', tbl_name: 'children').each do |idx|
        execute "DROP INDEX #{idx.name}"
      end
      execute "ALTER TABLE children RENAME TO old_children"

      eval old.string
      execute "INSERT INTO children (#{cols}) SELECT #{cols} FROM old_children"
      execute "DROP TABLE old_children"
    end

    def ruby_schema
      re = Regexp.new %Q|"(#{(RENAMES.keys + SPLITS.keys).join('|')})"|
      out = StringIO.new
      ActiveRecord::SchemaDumper.send(:new, Child.connection).send(:table, "children", StringIO.new).tap do |sio|
        sio.rewind
        sio.each_line do |line|
          out.puts line unless line =~ re
        end
      end
      out
    end
  end
end
