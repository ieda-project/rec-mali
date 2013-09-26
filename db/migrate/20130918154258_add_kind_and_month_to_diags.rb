class AddKindAndMonthToDiags < ActiveRecord::Migration
  def self.up
    add_column :diagnostics, :kind, :integer
    add_column :diagnostics, :month, :integer

    add_index :diagnostics, :kind
    add_index :diagnostics, :month

    execute 'UPDATE diagnostics SET kind=0 WHERE id IN (SELECT min(id) FROM diagnostics GROUP BY child_global_id)'
    execute 'UPDATE diagnostics SET kind=1 WHERE kind IS NULL'

    sql = case Diagnostic.connection.adapter_name
      when 'SQLite' then "strftime('%Y%m', done_on)"
      when 'PostgreSQL' then "extract(year from done_on)*100 + extract(month from done_on)"
      else raise 'Unsupported database'
    end
    execute "UPDATE diagnostics SET month=#{sql}"
  end

  def self.down
    remove_column :diagnostics, :month
    remove_column :diagnostics, :kind
  end
end
