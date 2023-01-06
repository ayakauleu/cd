package sc.dev.cd.crud;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.springframework.stereotype.Service;

import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class CrudService {

    public String selectArray(String[] pFields, String pFrom, String pWhere, String query) throws SQLException {

//        if (pFrom.contains("select")) sqlTemplate = pFrom;
//        else sqlTemplate = String.format("select * from %s where false", pFrom);

        String sqlTemplate = "select %s from (%s) q %s";
        var stSelect = pFields == null ? "*" : String.join(", ", pFields);
        var stFrom = pFrom;
        var stWhere = pWhere == null ? "" : "where " + pWhere;

        var sql = String.format(sqlTemplate, stSelect, query, stWhere);

        var url = "jdbc:postgresql://192.168.253.178:5435/kp";
        var conn = DriverManager.getConnection(url, "postgres", "postgres");
        var st = conn.prepareStatement(sql);
        var rs = st.executeQuery();
//        var rs = conn.getMetaData().getPrimaryKeys(null, null, tableName);
        var rsmd = rs.getMetaData();
        var columnCount = rsmd.getColumnCount();
        var ja = new JSONArray();
        while (rs.next()) {
            var jo = new JSONObject();
            for (var i = 1; i <= columnCount; i++) {
                var type = rsmd.getColumnClassName(i).substring(rsmd.getColumnClassName(i).lastIndexOf(".") + 1);
                var value = rs.getObject(i);
                var name = rsmd.getColumnName(i);
                if (type.equals("Timestamp") && value != null) {
                    jo.put(name, value.toString());
                } else {
                    jo.put(name, value);
                }
            }
            ja.add(jo);
        }

        return ja.toString();

//        JSONParser parser = new JSONParser();
//        JSONObject json = (JSONObject) parser.parse(stringToParse);
    }

    public String selectSingle(String[] pFields, String pFrom, String pWhere, String query) throws SQLException {
//        var sqlTemplate = "select * from %s %s";
//        var stWhere = whereClause == null ? null : "where " + whereClause;
//        var sql = String.format(sqlTemplate, tableName, stWhere);

        String sqlTemplate = "select %s from (%s) q %s";
        var stSelect = pFields == null ? "*" : String.join(", ", pFields);
        var stFrom = pFrom;
        var stWhere = pWhere == null ? "" : "where " + pWhere;

        var sql = String.format(sqlTemplate, stSelect, query, stWhere);

        var url = "jdbc:postgresql://192.168.253.178:5435/kp";
        var conn = DriverManager.getConnection(url, "postgres", "postgres");
        var st = conn.prepareStatement(sql);

        var rs = st.executeQuery();
//        var rs = conn.getMetaData().getPrimaryKeys(null, null, tableName);
        var rsmd = rs.getMetaData();
        var columnCount = rsmd.getColumnCount();

        var jo = new JSONObject();
        if (rs.next()) {
            for (var i = 1; i <= columnCount; i++) {
                jo.put(rsmd.getColumnName(i), rs.getObject(i));
            }
        }
        return jo.toString();

//        JSONParser parser = new JSONParser();
//        JSONObject json = (JSONObject) parser.parse(stringToParse);
    }

    public void update(String pTable, String pWhere, HashMap<String, String> pFields) throws SQLException {

        var stWhere = pWhere == null ? "" : "where " + pWhere;
        var stUpdate = pFields.entrySet()
                .stream()
                .map(e -> e.getKey()+"="+String.valueOf(e.getValue()))
                .collect(Collectors.joining(","));

        String sqlTemplate = "update %s set %s %s";
        var sql = String.format(sqlTemplate, pTable, stUpdate, stWhere);

        System.out.println(sql);

        var url = "jdbc:postgresql://192.168.253.178:5435/kp";
        var conn = DriverManager.getConnection(url, "postgres", "postgres");
        var st = conn.prepareStatement(sql);
        var rs = st.execute();
    }


    private JSONArray describe(String query) throws SQLException {
        var url = "jdbc:postgresql://192.168.253.178:5435/kp";
        var conn = DriverManager.getConnection(url, "postgres", "postgres");
        var sql = String.format("select * from (%s) q where false", query);
        var st = conn.prepareStatement(sql);

        var rsmd = st.getMetaData();
        var columnCount = rsmd.getColumnCount();

        var ja = new JSONArray();
        for (var i = 1; i <= columnCount; i++) {
//            jo.put(rsmd.getColumnName(i), rsmd.getColumnClassName(i).substring(rsmd.getColumnClassName(i).lastIndexOf(".") + 1));
            var jo = new JSONObject();
//            jo.put("value", rsmd.getColumnName(i));
            jo.put("text", rsmd.getColumnName(i));
            jo.put("type", rsmd.getColumnClassName(i).substring(rsmd.getColumnClassName(i).lastIndexOf(".") + 1));
            ja.add(jo);
        }
        return ja;
    }

    public String describeQuery(String query) throws SQLException {
        return describe(query).toString();
//        JSONParser parser = new JSONParser();
//        JSONObject json = (JSONObject) parser.parse(stringToParse);
    }

    public String describeTable(String table) throws SQLException {
        var url = "jdbc:postgresql://192.168.253.178:5435/kp";
        var conn = DriverManager.getConnection(url, "postgres", "postgres");
        var sql = String.format("select * from %s", table);
        var spl = table.split("\\.");
        ResultSet rs;
        if (spl.length == 2) {
            rs = conn.getMetaData().getPrimaryKeys(null, spl[0], spl[1]);
        } else {
            rs = conn.getMetaData().getPrimaryKeys(null, null, spl[0]);
        }
        String pk = "";
        while (rs.next()) {
            pk += rs.getString("COLUMN_NAME");
        }
        var fields = describe(sql);

        var jo = new JSONObject();
        jo.put("fields", fields);
        jo.put("pk", pk);
        jo.put("updating", table);

        return jo.toString();
//        JSONParser parser = new JSONParser();
//        JSONObject json = (JSONObject) parser.parse(stringToParse);
    }
}