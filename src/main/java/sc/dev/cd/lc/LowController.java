package sc.dev.cd.lc;

import org.json.simple.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import sc.dev.cd.keeper.KeeperService;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;

@RestController
@RequestMapping("/api/lc")
public class LowController {
    @Autowired
    private EntRepository entRepository;

    @Autowired
    private KeeperService keeperService;


    //actions
        @GetMapping("/projects/{projectId}/table/{pTable}/audit/{turnOn}")
    public void addAudit(@PathVariable("projectId") Long projectId, @PathVariable("pTable") String pTable, @PathVariable("turnOn") Boolean turnOn) throws SQLException {
        var connSt = keeperService.getConnStringForKeeper(projectId, 1L);
        var conn = DriverManager.getConnection(connSt);
        var sql = turnOn ? "SELECT dev_util.enable_tracking(?)" : "SELECT dev_util.disable_tracking(?)";
        var st = conn.prepareStatement(sql);
        st.setString(1, pTable);
        var rs = st.executeQuery();
    }

    @GetMapping("/projects/{projectId}/table/{pTable}/crud/{pk}")
    public void addCrud(@PathVariable("projectId") Long projectId, @PathVariable("pTable") String pTable, @PathVariable("pk") String pk) throws SQLException {
        var connSt = keeperService.getConnStringForKeeper(projectId, 1L);
        var conn = DriverManager.getConnection(connSt);
        //        var sql = turnOn ? "SELECT dev_util.crudify(?)" : "SELECT dev_util.disable_tracking(?)";
        var sql = "SELECT dev_util.crudify(?, ?)";
        var st = conn.prepareStatement(sql);
        st.setString(1, pTable);
        st.setString(2, pk);
        var rs = st.executeQuery();
    }

    @GetMapping("/projects/{projectId}/entity/{entityId}")
    public String getMeta(@PathVariable("projectId") Long projectId, @PathVariable("entityId") Integer entityId) throws SQLException {
        var connSt = keeperService.getConnStringForKeeper(projectId, 1L);
        var conn = DriverManager.getConnection(connSt);
        //        var sql = turnOn ? "SELECT dev_util.crudify(?)" : "SELECT dev_util.disable_tracking(?)";
        var sql = "SELECT meta.describe(?)";
        var st = conn.prepareStatement(sql);
        st.setInt(1, entityId);
        var rs = st.executeQuery();
        rs.next();
        return rs.getString(1);
    }

    @PostMapping("/projects/{projectId}/entity/{entityId}")
    public void addSome(@PathVariable("projectId") Long projectId, @PathVariable("entityId") Integer entityId, @RequestBody JSONObject params) throws SQLException {
        var connSt = keeperService.getConnStringForKeeper(projectId, 1L);
        var sql = "SELECT dev_util.create_crud_st(?, ?)";
        try (var conn = DriverManager.getConnection(connSt); var st = conn.prepareStatement(sql);) {
            st.setInt(1, entityId);
            st.setString(2, params.get("schema").toString());
            var rs = st.executeQuery();
        } catch (Exception e) {
            throw new SQLException(String.format("%s \n entity_id=%s, schema=%s", e.getMessage(), entityId, params.get("schema")));
        }
    }

    //entities
    @GetMapping("/projects/{projectId}/ent")
    public List<Ent> entList(@PathVariable("projectId") Integer projectId) {
        return entRepository.findByProjectIdOrderByEntityName(projectId);
    }

    //    @PatchMapping("/entities")
//    public void resUpdate(@RequestBody Ent ent) {
//        var old = entRepository.findById(ent.resourceId).get();
//        old.address = res.address;
//        old.login = res.login;
//        old.password = res.password;
//        old.typeId = res.typeId;
//        resourceRepository.save(old);
//    }
    @GetMapping("/projects/{projectId}/schema/{pSchema}/table/{pTable}")
    public void addEntity(@PathVariable("projectId") Long projectId, @PathVariable("pSchema") String pSchema, @PathVariable("pTable") String pTable) throws SQLException {
        var connSt = keeperService.getConnStringForKeeper(projectId, 1L);
        var sql = "SELECT dev_util.entity_add(?, ?)";
        try (var conn = DriverManager.getConnection(connSt); var st = conn.prepareStatement(sql);) {
            st.setString(1, pSchema);
            st.setString(2, pTable);
            var rs = st.executeQuery();
        } catch (Exception e) {
            throw new SQLException(String.format("%s \n entity=%s, schema=%s", e.getMessage(), pTable, pSchema));
        }
    }

    @PostMapping("/entities")
    public void resInsert(@RequestBody Ent res) {
        entRepository.save(res);
    }

    @DeleteMapping("/entities/{entId}")
    public void resDelete(@PathVariable("entId") Long entId) {
        var old = entRepository.findById(entId).get();
        entRepository.delete(old);
    }

    @GetMapping("/ent/{entId}")
    public Ent find(@PathVariable Long entId) {
        return entRepository.findById(entId).get();
    }


    @GetMapping("/test")
    public JSONObject testPost() {
        var resp = new HashMap<String, Object>();
        resp.put("result", true);
        resp.put("resultText", "Произошла ошибка");
        return new JSONObject(resp);
    }
}