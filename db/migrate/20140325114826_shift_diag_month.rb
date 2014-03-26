class ShiftDiagMonth < ActiveRecord::Migration
  class << self
    def up
      send Diagnostic.connection.adapter_name
    end

    def down
    end

    protected

    def SQLite
      execute "UPDATE diagnostics
        SET month=cast(strftime('%Y%m', date(done_on, '+6 days')) AS INTEGER)
        WHERE cast(strftime('%d', done_on) AS INTEGER) >= 26"
    end

    def PostgreSQL
      execute "CREATE OR REPLACE FUNCTION diagmonth(timestamp) RETURNS int AS
        'SELECT (extract(year from $1)*100+extract(month from $1))::integer;'
        LANGUAGE SQL"
      execute "UPDATE diagnostics
        SET month=diagmonth(done_on + interval '6 days')
        WHERE extract(day from done_on) >= 26"
    ensure
      execute "DROP FUNCTION IF EXISTS diagmonth(timestamp)"
    end
  end
end
