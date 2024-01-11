package sc.dev.cd.keeper;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import sc.dev.cd.IniYaml;
import sc.dev.cd.db.*;
import sc.dev.cd.tools.CliService;
import sc.dev.cd.tools.HttpService;

import java.io.IOException;
import java.nio.file.Files;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class ReleaseController {
    @Autowired
    private Environment env;
    @Autowired
    private KeeperService keeperService;
    @Autowired
    private ReleaseRepository releaseRepository;
    @Autowired
    private ReleaseHistoryRepository releaseHistoryRepository;
    @Autowired
    private StateRepository stateRepository;
    @Autowired
    private ResourceRepository resourceRepository;
    @Autowired
    private ProjectRepository projectRepository;
    @Autowired
    private ProjectSettingRepository projectSettingRepository;
    @Autowired
    private HttpService httpService;
    @Autowired
    private CliService cliService;

    @Autowired
    private IniYaml conf;

    //actions
    @PostMapping("/projects/{projectId}/sqls/add")
    public ResponseEntity<Long> sqlAdd(@PathVariable("projectId") Long projectId, @RequestBody SqlDto dto) throws Exception {
        var res = keeperService.scriptExecute(projectId, dto.sqlBody);
        if (res.isEmpty()) {
            var sqlId = releaseRepository.sqlAdd(dto.userId, dto.sqlBody, dto.taskId);
            return ResponseEntity.ok().body(sqlId);
        } else {
            throw new SQLException(res);
        }
    }

    @PostMapping("/projects/{projectId}/releases/make")
    public ResponseEntity<Long> make(@PathVariable("projectId") Long projectId, @RequestBody Map<String, String> relMap) throws Exception {
        String releaseName = relMap.getOrDefault("name", null);
        var sett = projectSettingRepository.findById(projectId).orElseThrow(() -> new Exception("Свойства проекта заполните плизз"));
        var dbType = projectRepository.findById(projectId).get().databaseTypeId;
        var releaseId = keeperService.releasePrepare(dbType, sett, releaseName);
        return ResponseEntity.ok().body(releaseId);
    }

    @GetMapping("/releases/{releaseId}/apply")
    public Release apply(@PathVariable("releaseId") Long releaseId) throws IOException, InterruptedException, SQLException {
        return keeperService.deltaApplyDo(releaseId);
    }

    @GetMapping("/releases/{releaseId}/revert")
    public Release revert(@PathVariable("releaseId") Long releaseId) throws IOException, InterruptedException, SQLException {
        return keeperService.deltaApplyUndo(releaseId);
    }

    @GetMapping("/releases/{releaseId}/genzip")
    public ResponseEntity<byte[]> genzip(@PathVariable("releaseId") Long releaseId) throws IOException, InterruptedException {
        var dbType = projectRepository.findById(releaseRepository.findById(releaseId).get().projectId).get().databaseTypeId;
        var zipFile = keeperService.genzip(releaseId, dbType);
        var bytes = Files.readAllBytes(zipFile);
        return httpService.downloadFile(bytes, LocalDateTime.now() + ".zip");
    }

    //projects
    @GetMapping("/projects")
    public List<Project> findAll() {
        return projectRepository.findAll();
    }

    @GetMapping("/projects/{projectId}")
    public Project find(@PathVariable Long projectId) {
        return projectRepository.findById(projectId).get();
    }

    @PatchMapping("/projects")
    public void projUpdate(@RequestBody Project res) {
        var old = projectRepository.findById(res.projectId).get();
        old.projectName = res.projectName;
        old.wipeComments = res.wipeComments;
        projectRepository.save(old);
    }

    @PostMapping("/projects")
    public Project projInsert(@RequestBody Project res) {
        return projectRepository.save(res);
    }

    @DeleteMapping("/projects/{projectId}")
    public void projDelete(@PathVariable("projectId") Long projectId) {
        projectRepository.deleteById(projectId);
    }

    //releases
    @GetMapping("/projects/{projectId}/releases")
    public List<Release> releaseList(@PathVariable("projectId") Long projectId) {
        return releaseRepository.findByProjectIdOrderByReleaseIdDesc(projectId);
    }

    @GetMapping("/releases/{releaseId}")
    public Release release(@PathVariable("releaseId") Long releaseId) {
        return releaseRepository.findById(releaseId).get();
    }

    @DeleteMapping("/releases/{releaseId}")
    public void relDelete(@PathVariable("releaseId") Long releaseId) {
        releaseRepository.deleteById(releaseId);
    }

    //resources
    @GetMapping("/projects/{projectId}/resources")
    public List<Resource> resourceList(@PathVariable("projectId") Integer projectId) {
        return resourceRepository.findByProjectId(projectId);
    }

    @GetMapping("/resources/{resourceId}")
    public Resource get(@PathVariable("resourceId") Long resourceId) {
        return resourceRepository.findById(resourceId).orElseThrow(() -> new RuntimeException("WTF"));
    }

    @PatchMapping("/resources")
    public void resUpdate(@RequestBody Resource res) {
        var old = resourceRepository.findById(res.resourceId).get();
        old.address = res.address;
        old.login = res.login;
        old.password = res.password;
        old.typeId = res.typeId;
        resourceRepository.save(old);
    }

    @PostMapping("/resources")
    public void resInsert(@RequestBody Resource res) {
        resourceRepository.save(res);
    }

    @DeleteMapping("/resources/{resourceId}")
    public void resDelete(@PathVariable("resourceId") Long resourceId) {
        var old = resourceRepository.findById(resourceId).get();
        resourceRepository.delete(old);
    }

    //release_history
    @GetMapping("/releases/{releaseId}/history")
    public List<ReleaseHistory> releaseHistory(@PathVariable("releaseId") Long releaseId) {
        return releaseHistoryRepository.findByReleaseIdOrderByHistoryIdDesc(releaseId);
    }

    //test
    @GetMapping("/download/{id}")
    public ResponseEntity<byte[]> download(@PathVariable("id") Long id) throws IOException {
        var bytes = keeperService.readFromDB(id);
        return httpService.downloadFile(bytes, id.toString() + ".sql");
    }

    @GetMapping("/test")
    public ResponseEntity<String>  test() throws Exception {
        conf.toString();
        return ResponseEntity.ok(keeperService.test());
        //   throw new Exception("Вот так");
    }

    @PostMapping("/cli/exec_remote")
    public ResponseEntity<String> execRemote(@RequestBody ExecRemoteModel model) throws Exception {
//        return ResponseEntity.ok(cmd);
        return ResponseEntity.ok(cliService.execRemote(model.cmd));
        //   throw new Exception("Вот так");
    }

//    @GetMapping("/test")
//    public JSONObject testPost() {
//        var resp = new HashMap<String, Object>();
//        resp.put("result", true);
//        resp.put("resultText", "Произошла ошибка");
//        return new JSONObject(resp);
//    }
}