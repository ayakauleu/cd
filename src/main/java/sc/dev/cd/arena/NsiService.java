package sc.dev.cd.arena;

import org.springframework.stereotype.Service;

import java.sql.DriverManager;
import java.sql.SQLException;

@Service
public class NsiService {
    public String execPostgresFunction(String funcName) throws SQLException {
        var url = "jdbc:postgresql://192.168.166.183:5434/arena";
        var conn = DriverManager.getConnection(url, "postgres", "postgres");
        var sql = String.format("select arena_api_ui.%s_list() as res;", funcName);
        var st= conn.prepareStatement(sql);
//        st.setString(1, fileBody);
        var rs = st.executeQuery();
        rs.next();
        return rs.getString("res");
    }

}
