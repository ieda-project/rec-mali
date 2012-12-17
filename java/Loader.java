import java.sql.*;
import java.io.File;
import java.util.Scanner;
import java.util.Map;
import java.util.HashMap;
import java.util.Iterator;

class Loader {
  static class ImportException extends Exception {
    public ImportException(String msg) { super(msg); }
  }

  static class ArgumentException extends Exception {
    public ArgumentException(String msg) { super(msg); }
  }

  static interface Column {
    public abstract void handle(int index, PreparedStatement st, String data) throws SQLException;
  }

  static class VARCHARColumn implements Column {
    public void handle(int index, PreparedStatement st, String data) throws SQLException {
      st.setString(index, data);
    }
  }

  static class TEXTColumn implements Column {
    public void handle(int index, PreparedStatement st, String data) throws SQLException {
      st.setString(index, data);
    }
  }

  static class DATEColumn implements Column {
    public void handle(int index, PreparedStatement st, String data) throws SQLException {
      st.setDate(index, java.sql.Date.valueOf(data));
    }
  }

  static class INTColumn implements Column {
    public void handle(int index, PreparedStatement st, String data) throws SQLException {
      st.setInt(index, Integer.parseInt(data));
    }
  }

  static class DATETIMEColumn implements Column {
    public void handle(int index, PreparedStatement st, String data) throws SQLException {
      st.setTimestamp(index, java.sql.Timestamp.valueOf(data));
    }
  }

  static class FLOATColumn implements Column {
    public void handle(int index, PreparedStatement st, String data) throws SQLException {
      st.setFloat(index, Float.parseFloat(data));
    }
  }

  static class INTEGERColumn implements Column {
    public void handle(int index, PreparedStatement st, String data) throws SQLException {
      st.setInt(index, Integer.parseInt(data));
    }
  }

  //       0       1            2      3      4     5
  // Args: serial, sqlite_file, table, model, zone, inputfile
  public static void main(String args[]) throws Exception {
    Scanner sc = new Scanner(new File(args[5]), "UTF-8").useDelimiter("\n");

    int serial = sc.nextInt();
    if (serial <= Integer.parseInt(args[0])) System.exit(0);

    String fieldlist = sc.next(); // TODO: check with regexp
    String[] fieldnames = fieldlist.split(",");
    int flen = fieldnames.length;

    Class.forName("org.sqlite.JDBC");
    Connection db = DriverManager.getConnection("jdbc:sqlite:"+args[1]);
    PreparedStatement st;

    // Getting the zone id
    int zoneid;
    {
      st = db.prepareStatement("SELECT id FROM zones WHERE name=?");
      st.setString(1, args[4]);
      ResultSet rs = st.executeQuery();
      if (!rs.next()) throw new ArgumentException("No such zone: "+args[4]);
      zoneid = rs.getInt("id");
    }

    // Types of the fields in the header
    int[] types = new int[flen+1];
    Column[] fields = new Column[flen+1];
    {
      Map<String,Integer> indexes = new HashMap<String,Integer>();
      for (int i=1; i <= flen; i++) indexes.put(fieldnames[i-1], i);
      ResultSet cols = db.getMetaData().getColumns(null, null, args[2], null);
      while (cols.next()) {
        String name = cols.getString(4);
        if (indexes.containsKey(name)) {
          int idx = indexes.get(name);

          String sqltype = cols.getString(6);
          int trimlen = sqltype.indexOf("(");
          if (trimlen > -1) sqltype = sqltype.substring(0, trimlen);

          if (!sqltype.equals("BOOLEAN"))
            fields[idx] = (Column) Class.forName(String.format("Loader$%sColumn", sqltype)).newInstance();
          types[idx] = Integer.parseInt(cols.getString(5));
        }
      }
    }

    db.setAutoCommit(false);
    //db.begin();

    try {
      db.createStatement().executeUpdate(
        String.format("DELETE FROM %s WHERE zone_id=%d", args[2], zoneid));
      st = db.prepareStatement(
        String.format("INSERT INTO %s (%s) VALUES (%s)",
          args[2], fieldlist, placeholders(flen)));

      while (sc.hasNext()) {
        for (int i = 1; i <= flen; i++) {
          String line = sc.next();
          switch (line.charAt(0)) {
            case ':': fields[i].handle(i, st, line.substring(1)); break;
            // case ':': st.setString(i, line.substring(1)); break;
            case 't': st.setBoolean(i, true); break;
            case 'f': st.setBoolean(i, false); break;
            case 'n': st.setNull(i, types[i]); break;
            default: throw new ImportException("Illegal format: "+line);
          }
        }
        st.executeUpdate();
      }

      // Done!
      st = db.prepareStatement("SELECT id FROM serial_numbers WHERE model=? AND zone_id=?");
      st.setString(1, args[3]);
      st.setInt(2, zoneid);
      ResultSet rs = st.executeQuery();
      if (rs.next()) {
        // Update
        st = db.prepareStatement("UPDATE serial_numbers SET value=?,exported=? WHERE id=?");
        st.setInt(1, serial);
        st.setBoolean(2, true);
        st.setInt(3, rs.getInt("id"));
      } else {
        // Insert
        st = db.prepareStatement("INSERT INTO serial_numbers (model,zone_id,value,exported) VALUES (?,?,?,?)");
        st.setString(1, args[3]);
        st.setInt(2, zoneid);
        st.setInt(3, serial);
        st.setBoolean(4, true);
      }
      st.executeUpdate();

      // Commit
      db.commit();
    } catch (Exception e) {
      System.err.println("FAIL: "+e.getMessage());
      try {
        db.rollback();
      } catch (Exception erb) {
        System.err.println("WARNING: rollback failed with "+erb.getMessage());
      }
      throw(e);
    }
  }

  /*
  private static String join(Collection<String> s, String delimiter) {
    StringBuilder builder = new StringBuilder();
    Iterator iter = s.iterator();
    while (iter.hasNext()) {
      builder.append(iter.next());
      if (!iter.hasNext()) {
        break;                  
      }
      builder.append(delimiter);
    }
    return builder.toString();
  }
  */

  private static String placeholders(int num) {
    StringBuilder builder = new StringBuilder();
    for (int i = 1; i < num; i++) builder.append("?,");
    builder.append("?");
    return builder.toString();
  }
}
