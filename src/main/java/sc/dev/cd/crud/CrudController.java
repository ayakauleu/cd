package sc.dev.cd.crud;

import org.json.simple.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.websocket.server.PathParam;
import java.sql.SQLException;
import java.util.HashMap;

@RestController
@RequestMapping("/api/crud")
public class CrudController {

    @Autowired
    private CrudService crudService;

    @PostMapping("/selectarray")
    public String selectArray(@RequestBody WhereModel model) throws SQLException {
        return crudService.selectArray(model.fields, model.from, model.where, model.query);
    }

    @PostMapping("/selectsingle")
    public String selectSingle(@RequestBody WhereModel model) throws SQLException {
        return crudService.selectSingle(model.fields, model.from, model.where, model.query);
    }
    @PostMapping("/describe")
    public String describeQuery(@RequestBody WhereModel model) throws SQLException {
        return crudService.describeQuery(model.query);
    }

    @GetMapping("/describe/{table}")
    public String describeTable(@PathVariable String table) throws SQLException {
        return crudService.describeTable(table);
    }

    @PatchMapping("/update")
    public void update(@RequestBody JSONObject model) throws SQLException {
        crudService.update(model.get("updating").toString(), model.get("where").toString(), (HashMap<String, String>) model.get("what"));
    }

}
