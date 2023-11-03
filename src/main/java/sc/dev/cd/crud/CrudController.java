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

    @PostMapping("/selectarray/{pid}")
    public String selectArray(@RequestBody WhereModel model, @PathVariable Long pid) throws SQLException {
        return crudService.selectArray(pid, model.fields, model.from, model.where, model.query);
    }

    @GetMapping("/selectarray/{pid}/{eid}")
    public String selectArray(@PathVariable Long pid, @PathVariable Integer eid) throws SQLException {
        return crudService.selectArray(pid, eid );
    }

    @PostMapping("/selectsingle/{pid}")
    public String selectSingle(@RequestBody WhereModel model, @PathVariable Long pid) throws SQLException {
        return crudService.selectSingle(pid, model.fields, model.from, model.where, model.query);
    }

    @PatchMapping("/update")
    public void update(@RequestBody JSONObject model) throws SQLException {
        crudService.update(Long.valueOf(model.get("pid").toString()), model.get("updating").toString(), model.get("where").toString(), (HashMap<String, String>) model.get("what"));
    }

    @PostMapping("/insert")
    public void insert(@RequestBody JSONObject model) throws SQLException {
        crudService.insert(Long.valueOf(model.get("pid").toString()), model.get("table").toString(), (HashMap<String, Object>) model.get("what"));
    }

    @PostMapping("/delete/{pid}")
    public void delete(@RequestBody WhereModel model, @PathVariable Long pid) throws SQLException {
        crudService.delete(pid, model.table, model.where);
    }

    @PostMapping("/describe/{pid}")
    public String describeQuery(@RequestBody WhereModel model, @PathVariable Long pid) throws SQLException {
        return crudService.describeQuery(pid, model.query);
    }

    @GetMapping("/describe/{pid}/{table}")
    public String describeTable(@PathVariable String table, @PathVariable Long pid) throws SQLException {
        return crudService.describeTable(pid, table);
    }
}