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

  //       0       1            2      3      4     5
  // Args: serial, sqlite_file, table, model, zone, inputfile
  public static void main(String args[]) throws Exception {
    Scanner sc = new Scanner(new File(args[5]), "UTF-8").useDelimiter("\n");

    int serial = sc.nextInt();
    if (serial <= Integer.parseInt(args[0])) System.exit(0);

    String fieldlist = sc.next(); // TODO: check with regexp
    String[] fields = fieldlist.split(",");
    int flen = fields.length;

    Class.forName("org.sqlite.JDBC");
    Connection db = DriverManager.getConnection("jdbc:sqlite:"+args[1]);

    // Getting the zone id
    int zoneid;
    {
      PreparedStatement st = db.prepareStatement("SELECT id FROM zones WHERE name=?");
      st.setString(1, args[4]);
      ResultSet rs = st.executeQuery();
      if (!rs.next()) throw new ArgumentException("No such zone: "+args[4]);
      zoneid = rs.getInt("id");
    }

    // Types of the fields in the header
    int[] types = new int[flen];
    {
      Map<String,Integer> indexes = new HashMap<String,Integer>();
      for (int i=0; i < flen; i++) indexes.put(fields[i], i);
      ResultSet cols = db.getMetaData().getColumns(null, null, args[2], null);
      while (cols.next()) {
        String name = cols.getString(4);
        if (indexes.containsKey(name))
          types[indexes.get(name)] = new Integer(cols.getString(5));
      }
    }

    db.setAutoCommit(false);
    db.begin();

    try {
      db.createStatement().executeUpdate("DELETE FROM "+args[2]+" WHERE global_id LIKE '%"+args[4]+"/%'");
      PreparedStatement st = db.prepareStatement(
        "INSERT INTO "+args[2]+" ("+fieldlist+") VALUES ("+placeholders(flen)+")");

      while (sc.hasNext()) {
        for (int i = 1; i <= flen; i++) {
          String line = sc.next();
          switch (line.charAt(0)) {
            case ':': st.setString(i, line.substring(1)); break;
            case 't': st.setBoolean(i, true); break;
            case 'f': st.setBoolean(i, false); break;
            case 'n': st.setNull(i, types[i-1]); break;
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