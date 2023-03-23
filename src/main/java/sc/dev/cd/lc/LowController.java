package sc.dev.cd.lc;

import org.json.simple.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import sc.dev.cd.keeper.KeeperService;
import sc.dev.cd.model.Resource;

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