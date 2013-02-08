import java.io.BufferedWriter;
import java.io.OutputStreamWriter;
import java.io.FileOutputStream;
import java.sql.*;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

class Dumper {
  static abstract class Column {
    protected String name;
    public Column(String n) { name = n; }
    public abstract String dump(ResultSet res) throws SQLException;
  }

  static class BooleanColumn extends Column {
    public BooleanColumn(String n) { super(n); }
    public String dump(ResultSet res) throws SQLException {
      boolean value = res.getBoolean(name);
      if (res.wasNull()) return "n";
      return value ? "t" : "f";
    }
  }

  static class TextColumn extends Column {
    public TextColumn(String n) { super(n); }
    public String dump(ResultSet res) throws SQLException {
      String value = res.getString(name);
      return value == null ? "n" : ":" +
        value.replaceAll("\"", "\\\"").replaceAll("\n", "\\n").replaceAll("\r", "").replaceAll("\\p{Cntrl}", " ").trim();
    }
  }

  static class OtherColumn extends Column {
    public OtherColumn(String n) { super(n); }
    public String dump(ResultSet res) throws SQLException {
      String value = res.getString(name);
      return value == null ? "n" : ":"+value;
    }
  }

  // Args: header, file, table, where, outputfile
  public static void main(String args[]) throws Exception {
    BufferedWriter out = new BufferedWriter(
      new OutputStreamWriter(
        new FileOutputStream(args[4]), "UTF8"));

    out.write(args[0]);
    out.newLine();

    Class.forName("org.sqlite.JDBC");
    Connection db = DriverManager.getConnection("jdbc:sqlite:"+args[1]);

    ResultSet colset = db.getMetaData().getColumns(null, null, args[2], null);
    List<Column> columns = new ArrayList<Column>(32);
    boolean first = true;
    while (colset.next()) {
      String n = colset.getString(4);
      if (!n.equals("id") && !n.equals("zone_id")) {
        Column col = null;
        String type = colset.getString(6);
        out.write(first ? n : ","+n); first = false;

        if (type.equals("BOOLEAN")) {
          col = new BooleanColumn(n);
        } else if (type.indexOf("VARCHAR") >= 0) {
          col = new TextColumn(n);
        } else {
          col = new OtherColumn(n);
        }
        columns.add(col);
      }
    }
    out.newLine();

    PreparedStatement st = db.prepareStatement(
      "SELECT * FROM "+ args[2] +
      " WHERE " + args[3] + " AND id > ? ORDER BY id ASC LIMIT 500");
    st.setInt(1, 0);
    int lastid = 0;
    while (true) {
      ResultSet res = st.executeQuery();
      int count = 0;
      while (res.next()) {
        count++;
        Iterator<Column> it = columns.iterator();
        while (it.hasNext())  {
          out.write(it.next().dump(res));
          out.newLine();
        }
        lastid = res.getInt("id");
      }
      if (count == 0) break;
      st.setInt(1, lastid);
    }

    out.close();
  }
}
