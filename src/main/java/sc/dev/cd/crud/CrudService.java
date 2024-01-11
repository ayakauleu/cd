package sc.dev.cd.crud;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import sc.dev.cd.keeper.KeeperService;

import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class CrudService {
    @Autowired
    private KeeperService keeperService;

    public String selectArray(Long projectId, String[] pFields, String pFrom, String pWhere, String query) throws SQLException {
//        if (pFrom.contains("select")) sqlTemplate = pFrom;
//        else sqlTemplate = String.format("select * from %s where false", pFrom);

        String sqlTemplate = "select %s from (%s) q %s";
        var stSelect = pFields == null ? "*" : String.join(", ", pFields);
        var stFrom = pFrom;
        var stWhere = pWhere == null ? "" : "where " + pWhere;

        var sql = String.format(sqlTemplate, stSelect, query, stWhere);

//        var url = "jdbc:postgresql://192.168.253.178:5435/kp";
//        var conn = DriverManager.getConnection(url, "postgres", "postgres");
//        var pool = BasicConnectionPool.create(url, "postgres", "postgres");
//        var conn = pool.getConnection();

        var connSt = keeperService.getConnStringForKeeper(projectId, 1L);

        try (var conn = DriverManager.getConnection(connSt); var st = conn.prepareStatement(sql);) {
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
                    if ((type.equals("Timestamp") || type.equals("Date") || type.equals("UUID")) && value != null) {
                        jo.put(name, value.toString());
                    } else {
                        jo.put(name, value);
                    }
                }
                ja.add(jo);
            }

            return ja.toString();
        }

//        JSONParser parser = new JSONParser();
//        JSONObject json = (JSONObject) parser.parse(stringToParse);
    }

    public String selectArray(Long projectId, Integer entityId) throws SQLException {

        return selectArray(projectId, null, null, null, "select * from kp_core.supplier");
    }

//        JSONParser parser = new JSONParser();
//        JSONObject json = (JSONObject) parser.parse(stringToParse);

    public String selectSingle(Long projectId, String[] pFields, String pFrom, String pWhere, String query) throws
            SQLException {
//        var sqlTemplate = "select * from %s %s";
//        var stWhere = whereClause == null ? null : "where " + whereClause;
//        var sql = String.format(sqlTemplate, tableName, stWhere);

        String sqlTemplate = "select %s from (%s) q %s";
        var stSelect = pFields == null ? "*" : String.join(", ", pFields);
        var stFrom = pFrom;
        var stWhere = pWhere == null ? "" : "where " + pWhere;

        var sql = String.format(sqlTemplate, stSelect, query, stWhere);

        var connSt = keeperService.getConnStringForKeeper(projectId, 1L);
        try (var conn = DriverManager.getConnection(connSt); var st = conn.prepareStatement(sql);) {

            var rs = st.executeQuery();
//        var rs = conn.getMetaData().getPrimaryKeys(null, null, tableName);
            var rsmd = rs.getMetaData();
            var columnCount = rsmd.getColumnCount();

            var jo = new JSONObject();
            if (rs.next()) {
                for (var i = 1; i <= columnCount; i++) {
                    var type = rsmd.getColumnClassName(i).substring(rsmd.getColumnClassName(i).lastIndexOf(".") + 1);
                    var value = rs.getObject(i);
                    var name = rsmd.getColumnName(i);
                    if ((type.equals("Timestamp") || type.equals("Date") || type.equals("UUID")) && value != null) {
                        jo.put(name, value.toString());
                    } else {
                        jo.put(name, value);
                    }
                }
            }
            return jo.toString();
        }
//        JSONParser parser = new JSONParser();
//        JSONObject json = (JSONObject) parser.parse(stringToParse);
    }

    public void update(Long projectId, String pTable, String pWhere, HashMap<String, String> pFields) throws
            SQLException {

        var stWhere = pWhere == null ? "" : "where " + pWhere;
        var stUpdate = pFields.entrySet()
                .stream()
                .map(e -> e.getKey() + " = '" + String.valueOf(e.getValue()) + "'")
                .collect(Collectors.joining(","));

        String sqlTemplate = "update %s set %s %s";
        var sql = String.format(sqlTemplate, pTable, stUpdate, stWhere);

        var connSt = keeperService.getConnStringForKeeper(projectId, 1L);
        try (var conn = DriverManager.getConnection(connSt); var st = conn.prepareStatement(sql);) {
            var rs = st.execute();
        } catch (Exception e) {
            throw new SQLException(String.format("%s \nin %s", e.getMessage(), sql));
        }
    }

    public void delete(Long projectId, String pTable, String pWhere) throws
            SQLException {
        var stWhere = pWhere == null ? "false" : pWhere;
        String sqlTemplate = "delete from %s where %s";
        var sql = String.format(sqlTemplate, pTable, stWhere);
        var connSt = keeperService.getConnStringForKeeper(projectId, 1L);
        try (var conn = DriverManager.getConnection(connSt); var st = conn.prepareStatement(sql); ) {
            var rs = st.execute();
        } catch (Exception e) {
            throw new SQLException(String.format("%s \nin %s", e.getMessage(), sql));
        }
    }

    public void insert(Long projectId, String pTable, HashMap<String, Object> pFields) throws SQLException {
        var stNames = String.join(",", pFields.keySet());
        var stValues = pFields.values()
                .stream().map(item -> "'" + item + "'")
                .collect(Collectors.joining(","));
        String sqlTemplate = "insert into %s(%s) values (%s)";
        var sql = String.format(sqlTemplate, pTable, stNames, stValues);

        var connSt = keeperService.getConnStringForKeeper(projectId, 1L);
        try (var conn = DriverManager.getConnection(connSt); var st = conn.prepareStatement(sql);) {
            var rs = st.execute();
        }
    }


    private JSONArray describe(Long projectId, String query) throws SQLException {
        var sql = String.format("select * from (%s) q where 1 = 0", query);
        var connSt = keeperService.getConnStringForKeeper(projectId, 1L);
        try (var conn = DriverManager.getConnection(connSt); var st = conn.prepareStatement(sql);) {

            var rsmd = st.getMetaData();
            var columnCount = rsmd.getColumnCount();

            var ja = new JSONArray();
            for (var i = 1; i <= columnCount; i++) {
//            jo.put(rsmd.getColumnName(i), rsmd.getColumnClassName(i).substring(rsmd.getColumnClassName(i).lastIndexOf(".") + 1));
                var jo = new JSONObject();
//            jo.put("value", rsmd.getColumnName(i));
                jo.put("text", rsmd.getColumnName(i));
                jo.put("value", rsmd.getColumnName(i));
                jo.put("type", rsmd.getColumnClassName(i).substring(rsmd.getColumnClassName(i).lastIndexOf(".") + 1));
                jo.put("sql_type", rsmd.getColumnTypeName(i));
                ja.add(jo);
            }
            return ja;
        }
    }

    public String describeQuery(Long pid, String query) throws SQLException {
        return describe(pid, query).toString();
//        JSONParser parser = new JSONParser();
//        JSONObject json = (JSONObject) parser.parse(stringToParse);
    }

    public String describeTable(Long pid, String table) throws SQLException {

        var sql = String.format("select * from %s", table);
        var connSt = keeperService.getConnStringForKeeper(pid, 1L);
        try (var conn = DriverManager.getConnection(connSt); var st = conn.prepareStatement(sql);) {

            var spl = table.split("\\.");
            ResultSet rs;
            if (spl.length == 2) {
                rs = conn.getMetaData().getPrimaryKeys(null, spl[0], spl[1]);
            } else {
                rs = conn.getMetaData().getPrimaryKeys(null, null, spl[0]);
            }
            StringBuilder pk = new StringBuilder();
            while (rs.next()) {
                pk.append(rs.getString("COLUMN_NAME"));
            }
            var fields = describe(pid, sql);

            var jo = new JSONObject();
            jo.put("fields", fields);
            jo.put("pk", pk.toString());
            jo.put("updating", table);

            return jo.toString();
        }
//        JSONParser parser = new JSONParser();
//        JSONObject json = (JSONObject) parser.parse(stringToParse);
    }
}