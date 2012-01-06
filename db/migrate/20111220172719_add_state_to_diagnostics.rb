class AddStateToDiagnostics < ActiveRecord::Migration
  def self.up
    add_column :diagnostics, :state, :string
    db = Diagnostic.connection
    db.execute "
      UPDATE diagnostics
      SET state='calculated'
      WHERE global_id IN (#{Result.select('DISTINCT diagnostic_global_id').to_sql})"
    db.execute "
      UPDATE diagnostics 
      SET state='filled'
      WHERE state IS NULL
      AND global_id IN (#{SignAnswer.select('DISTINCT diagnostic_global_id').to_sql})"
    db.execute "UPDATE diagnostics SET state='opened' WHERE state IS NULL"
  end

  def self.down
    remove_column :diagnostics, :state
  end
end
