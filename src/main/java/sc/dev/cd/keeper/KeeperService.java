package sc.dev.cd.keeper;

import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import sc.dev.cd.conf.NekiiClass;
import sc.dev.cd.model.ProjectSetting;
import sc.dev.cd.model.Release;
import sc.dev.cd.tools.CliService;

import java.io.IOException;
import java.io.Writer;
import java.net.URI;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.sql.DriverManager;
import java.sql.SQLException;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@AllArgsConstructor
public class KeeperService {

    //    final public String cmd = """
//        call C:\\dev\\postgres\\pgCodeKeeper-cli6\\pgcodekeeper-cli ^
//        --in-charset utf-8 --out-charset utf-8 ^
//        -t "jdbc:postgresql://192.168.253.178:5434/kp?user=postgres&password=postgres" ^
//        -s "jdbc:postgresql://192.168.253.178:5435/kp?user=postgres&password=postgres" ^
//        -o test-dev-utf.sql ^
//        -I d:\\work\\cabinet\\deploy\\.pgcodekeeperignore
//    """;

    @Autowired
    private NekiiClass nc;

    @Autowired
    private Environment env;

    @Autowired
    private ReleaseRepository releaseRepository;

    @Autowired
    private StateRepository stateRepository;

    @Autowired
    private ProjectSettingRepository projectSettingRepository;

    @Autowired
    private CliService cliService;

    final private String CMD_PREPARE = "%s --in-charset utf-8 --out-charset utf-8 --ignore-column-order -t \"%s\" -s \"%s\" -o %s -I %s";
    final private String CMD_APPLY = "psql -f %s %s";

    public Long releasePrepare(int dbType, ProjectSetting projectSetting, String releaseName) throws SQLException, IOException, InterruptedException {
        if (dbType == 2) return releasePreparePg(projectSetting, releaseName);
        else return releasePrepareOra(projectSetting, releaseName);
    }

    public Long releasePreparePg(ProjectSetting projectSetting, String releaseName) throws IOException, InterruptedException, SQLException {
        //Читаем параметры команды из конфигурации
        var exePath = Paths.get(env.getProperty("keeper-cli.bin"));
        var doPath = Paths.get(env.getProperty("keeper-cli.working-folder"), env.getProperty("keeper-cli.do-file-name"));
        var undoPath = Paths.get(env.getProperty("keeper-cli.working-folder"), env.getProperty("keeper-cli.undo-file-name"));
        var ignorePath = Paths.get(env.getProperty("keeper-cli.working-folder"), "pgCodeKeeperIgnore-" + projectSetting.projectId.toString());
        var targetConn = getConnStringForKeeper(projectSetting.projectId, 2L);
        var sourceConn = getConnStringForKeeper(projectSetting.projectId, 1L);

        //Выгружаем pgCodeKeeperIgnore
        Files.write(ignorePath, projectSetting.keeperFilter.getBytes());
        //Формируем командную строку
        String doCmd = String.format(CMD_PREPARE, exePath, targetConn, sourceConn, doPath, ignorePath);
//        String doCmd = cliPrepareDo(projectId);
        //Создаем файл наката
        var doMap = cliService.execConsole(doCmd);
        var doBody = new String(Files.readAllBytes(doPath));
        if (projectSetting.wipeComments) {
            doBody = wipeComments(doBody);
        }
        if (!doMap.err().isBlank())
            throw new ResponseStatusException(HttpStatus.I_AM_A_TEAPOT, doMap.err(), null);

        if (doBody.trim().isBlank())
            throw new ResponseStatusException(HttpStatus.I_AM_A_TEAPOT, "Объекты баз идентичны, обновление не требуется", null);

        //Формируем командную строку
        String undoCmd = String.format(CMD_PREPARE, exePath, sourceConn, targetConn, undoPath, ignorePath);
        //Создаем файл отката
        cliService.execConsole(undoCmd);
        var undoBody = new String(Files.readAllBytes(undoPath));

        //Формируем релиз в памяти
        var release = new Release();
        release.projectId = projectSetting.projectId;
        release.releaseName = releaseName;
        release.state = stateRepository.getById(1);
        release.body = doBody;
        release.undo = undoBody;
        release.dateExecute = LocalDateTime.now();

        //Сохраняем релиз в БД
        var releaseId = releaseRepository.save(release).releaseId;
        return releaseId;
    }

    public Long releasePrepareOra(ProjectSetting projectSetting, String releaseName) {
        return releaseRepository.releasePrepare(projectSetting.projectId.intValue(), 1, releaseName);
    }

    public String wipeComments(String content) {
        return Arrays.stream(content.split("\\n\\n"))
                .filter(st -> !( /*st.isBlank() ||*/ st.startsWith("COMMENT ON ")))
//                .map(/*convert string*/)
                .collect(Collectors.joining(System.lineSeparator()));
    }

    public Release deltaApplyDo(Long releaseId) throws IOException, InterruptedException, SQLException {
        var release = releaseRepository.findById(releaseId).get();
        var path = Paths.get(env.getProperty("keeper-cli.working-folder"), env.getProperty("keeper-cli.do-file-name"));
        Files.writeString(path, release.body);
        var cmdApply = String.format(CMD_APPLY, path, getConnStringForPsql(release.projectId, 2L));
        var cliResp = cliService.execConsole(cmdApply);

        release.io = cliResp.io();
        release.err = cliResp.err();
        release.state = stateRepository.getById(2);

        releaseRepository.save(release);
        return release;
    }

    public Release deltaApplyUndo(Long releaseId) throws IOException, InterruptedException, SQLException {
        var release = releaseRepository.findById(releaseId).get();
        var path = Paths.get(env.getProperty("keeper-cli.working-folder"), env.getProperty("keeper-cli.undo-file-name"));
        Files.writeString(path, release.undo);
        var cmdApply = String.format(CMD_APPLY, path, getConnStringForPsql(release.projectId, 2L));
        var cliResp = cliService.execConsole(cmdApply);

        release.io = cliResp.io();
        release.err = cliResp.err();
        release.state = stateRepository.getById(3);

        releaseRepository.save(release);
        return release;
    }

    public String getConnStringForKeeper(Long projectId, Long typeId) throws SQLException {
        var url = "jdbc:postgresql://192.168.253.178:5435/kp";
        var sql = "select address, login, password from release.project_resource where project_id = ? and type_id = ?";
        try (var conn = DriverManager.getConnection(url, "postgres", "postgres"); var st = conn.prepareStatement(sql);) {
            st.setLong(1, projectId);
            st.setLong(2, typeId);
            var rs = st.executeQuery();
            rs.next();

            var template = "jdbc:postgresql://%s?user=%s&password=%s";
            var filled = String.format(template, rs.getString(1), rs.getString(2), rs.getString(3));
            return filled;
        }
    }

    public String getConnStringForPsql(Long projectId, Long typeId) throws SQLException {
        var url = "jdbc:postgresql://192.168.253.178:5435/kp";
        var sql = "select address, login, password from release.project_resource where project_id = ? and type_id = ?";
        try (var conn = DriverManager.getConnection(url, "postgres", "postgres"); var st = conn.prepareStatement(sql); ) {
            st.setLong(1, projectId);
            st.setLong(2, typeId);
            var rs = st.executeQuery();
            rs.next();

            var template = "postgresql://%s:%s@%s";
            var filled = String.format(template, rs.getString(2), rs.getString(3), rs.getString(1));
            return filled;
        }
    }

    public byte[] readFromDB(Long releaseId) {
        return releaseRepository.downloadReleaseBody(releaseId).getBytes(StandardCharsets.UTF_8);
        //Files.readAllBytes(Paths.get("d:\\test-dev-utf.sql"));
    }

    public Path genzip(Long releaseId, Integer dbType) throws IOException, InterruptedException {
        String st;
        String charsetName;

        if (dbType == 2) {
            //Postgres
            st = releaseRepository.findById(releaseId).get().body;
            charsetName = "UTF-8";
        } else {
            //Oracle
            st = releaseRepository.releaseGatherFromDB(releaseId);
            charsetName = "windows-1251";
        }

        return zipFromString(st, Charset.forName(charsetName));
    }

    public Path zipFromString(String st, Charset charset) throws IOException {
        Map<String, String> zipEnv = new HashMap<>();
        zipEnv.put("create", "true");
        Path path = Paths.get(env.getProperty("keeper-cli.working-folder"), "db_update.zip");
        URI uri = URI.create("jar:" + path.toUri());
        try (FileSystem fs = FileSystems.newFileSystem(uri, zipEnv)) {
            Path nf = fs.getPath("update", "update_db.sql");
            try (Writer writer = Files.newBufferedWriter(nf, charset, StandardOpenOption.CREATE)) {
                writer.write(st);
//                release.state = stateRepository.getById(4);
//                releaseRepository.save(release);
            }
        }
        return path;
    }

    public String test() throws Exception {

        return cliService.execRemote("ls -l");

//        for (int i = 0; i < 100000; i++) {
//            Thread.startVirtualThread(
//                    () -> {
//                        try {
//                            Thread.sleep(1000);
//                        } catch (InterruptedException e) {
//                            throw new RuntimeException(e);
//                        }
//                    }
//            );
//        }

//        var url = "jdbc:postgresql://192.168.253.178:5432/kp_sms";
//        var conn = DriverManager.getConnection(url, "postgres", "postgres");
//        var text = "jnkojko hjhj jhiopjhiopjh jhiopjhiop jiopfgyui gbuhigh";
//        var st = conn.prepareStatement("select * from dev_utils.file_ WHERE id = 4");
//        var rs = st.executeQuery();
//        var b = rs.getBlob(1);


//        for (int i = 0; i < 200; i++) {
//            final int index = i;
//            Thread.ofVirtual().start(
//                    () -> {
//                        try {
//                            var url = "jdbc:postgresql://192.168.253.178:5432/kp_sms";
//                            Connection conn = null;
//                            conn = DriverManager.getConnection(url, "kp_sms", "kp_sms");
//                            var text = "Celery jhiopjhiopjh jhiopjhiop jiopfgyui gbuhigh";
//                            //throw new Exception("Polundra");
//                            var st = conn.prepareStatement("select utl_sms.sms_create_varchar('alias3', '375297753577', ?, null, null);");
//                            st.setString(1, text);
//                            var rs = st.executeQuery();
//                        } catch (SQLException e) {
//                            throw new RuntimeException(e);
//                        }
//
//                        System.out.println("Printing: " + index);
//                    }
//            );
//        }
//
//
//        var url = "jdbc:postgresql://192.168.253.178:5432/kp_sms";
//        var conn = DriverManager.getConnection(url, "kp_sms", "kp_sms");
//        var text = "jnkojko hjhj jhiopjhiopjh jhiopjhiop jiopfgyui gbuhigh";
//        Thread.sleep(2000);
//        //throw new Exception("Polundra");
//        var st = conn.prepareStatement("select utl_sms.sms_create_varchar('alias3', '375297753577', ?, null, null);");
//        st.setString(1, text);
//        var rs = st.executeQuery();

//        Map<String, String> env = new HashMap<>();
//        env.put("create", "true");
//        Path path = Paths.get("d:\\", "teat.zip");
//        URI uri = URI.create("jar:" + path.toUri());
//        try (FileSystem fs = FileSystems.newFileSystem(uri, env)) {
//            Path nf = fs.getPath("new.txt");
//            try (Writer writer = Files.newBufferedWriter(nf, StandardCharsets.UTF_8, StandardOpenOption.CREATE)) {
//                writer.write("Приветик");
//            }
//        }

//        var process = Runtime.getRuntime().exec("psql -f d:\\test.sql postgresql://postgres:postgres@192.168.253.178:5435/kp");
//        var code = process.waitFor();
//
//        var io = new BufferedReader(new InputStreamReader(process.getInputStream()));
//        var err = new BufferedReader(new InputStreamReader(process.getErrorStream()));
//        String line;
//        while (true) {
//            line = io.readLine();
//            if (line == null) {
//                break;
//            }
//            System.out.println(line);
//        }
    }

    public String scriptExecute(Long projectId, String sqlBody) throws IOException, SQLException, InterruptedException {
//        var release = releaseRepository.findById(releaseId).get();
        var path = Paths.get(env.getProperty("keeper-cli.working-folder"), env.getProperty("keeper-cli.do-file-name"));
        Files.writeString(path, sqlBody);
        var cmdApply = String.format(CMD_APPLY, path, getConnStringForPsql(projectId, 2L));
        var cliResp = cliService.execConsole(cmdApply);

        return cliResp.err();
    }

//    public int log(Long projectId, String fileBody, String io, String err) throws SQLException {
//        var url = "jdbc:postgresql://192.168.253.178:5435/kp";
//        var conn = DriverManager.getConnection(url, "postgres", "postgres");
//        var st = conn.prepareStatement("select release.log(?, ?, ?, ?);");
//        st.setLong(1, projectId);
//        st.setString(2, fileBody);
//        st.setString(3, io);
//        st.setString(4, err);
//        var rs = st.executeQuery();
//        rs.next();
//        return rs.getInt(1);
//    }

    //    public String cliPrepareDo(Project project) throws SQLException, IOException {
//        //Выгружаем pgignore
//        var pgIgnorePath = Paths.get(env.getProperty("keeper-cli.working-folder"),"pgCodeKeeperIgnore-" + project.projectId.toString());
//        var res = Files.write(pgIgnorePath, projectSettingRepository.findById(projectId).get().keeperFilter.getBytes());
//        return String.format(CMD_PREPARE,
//                env.getProperty("keeper-cli.bin"),
//                getConnStringForKeeper(projectId, 2L),
//                getConnStringForKeeper(projectId, 1L),
//                env.getProperty("keeper-cli.working-folder") + "\\" + env.getProperty("keeper-cli.do-file-name"),
//                pgIgnorePath);
//    }
//
//    public String cliPrepareUndo(Long projectId) throws SQLException {
//        return String.format(CMD_PREPARE,
//                env.getProperty("keeper-cli.bin"),
//                getConnStringForKeeper(projectId, 1L),
//                getConnStringForKeeper(projectId, 2L),
//                env.getProperty("keeper-cli.working-folder") + "\\" + env.getProperty("keeper-cli.undo-file-name"),
//                env.getProperty("keeper-cli.ignore"));
//    }

}