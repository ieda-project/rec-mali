require 'stringio'

class NewAndSplitVaccinations < ActiveRecord::Migration
  CHANGES = {
    'bcg_polio0'    => %w(v_bcg v_polio0),
    'penta1_polio1' => %w(v_penta1 v_polio1),
    'penta2_polio2' => %w(v_penta2 v_polio2),
    'penta3_polio3' => %w(v_penta3 v_polio3),
    'measles'       => %w(v_measles1)
  }

  NEW = %w(v_pneumo v_rota v_measles_r16)

  class << self
    def up
      for col in Child::VACCINATIONS.keys
        add_column :children, col, :integer
      end

      for src, dst in CHANGES
        y = dst.map { |i| "#{i}=1" }.join(',')
        n = dst.map { |i| "#{i}=0" }.join(',')
        execute "UPDATE children SET #{y} WHERE #{src}='t'"
        execute "UPDATE children SET #{n} WHERE #{src}='f'"
      end

      send Child.connection.adapter_name.downcase

      Child.reset_column_information
    end

    def down
      raise ActiveRecord::IrreversibleMigration
    end

    protected

    def postgresql
      CHANGES.keys.each { |i| remove_column :children, i }
    end

    def sqlite
      meta = Class.new ActiveRecord::Base
      meta.table_name = 'sqlite_master'
      meta.inheritance_column = :bogus

      Child.reset_column_information
      cols = (Child.column_names - CHANGES.keys).join(',')
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
      re = Regexp.new %Q|"(#{(CHANGES.keys).join('|')})"|
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
