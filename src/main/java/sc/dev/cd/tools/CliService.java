package sc.dev.cd.tools;

import org.springframework.stereotype.Service;
import sc.dev.cd.db.CliResponse;
import com.jcraft.jsch.*;

import java.io.IOException;
import java.io.InputStream;

@Service
public class CliService {

    public CliResponse execConsole(String cmd) throws IOException, InterruptedException {
        var process = Runtime.getRuntime().exec(cmd);
        var code = process.waitFor();
//        var io = new BufferedReader(new InputStreamReader(process.getInputStream()));
//        var err = new BufferedReader(new InputStreamReader(process.getErrorStream()));
        var io = new String(process.getInputStream().readAllBytes());
        var err = new String(process.getErrorStream().readAllBytes());

        return new CliResponse(io, err);
    }

    private static final String REMOTE_HOST = "localhost";
    private static final String USERNAME = "SCDC\\yakauleu";
//    private static final String REMOTE_HOST = "192.168.253.178";
//    private static final String USERNAME = "root";
    private static final int REMOTE_PORT = 22;
    private static final int SESSION_TIMEOUT = 10000;
    private static final int CHANNEL_TIMEOUT = 5000;

    public String execRemote(String cmd) {

        Session jschSession = null;
        var b = new StringBuilder();

        try {

            JSch jsch = new JSch();
//            jsch.setKnownHosts("/home/mkyong/.ssh/known_hosts");
            jschSession = jsch.getSession(USERNAME, REMOTE_HOST, REMOTE_PORT);

            // not recommend, uses jsch.setKnownHosts
            jschSession.setConfig("StrictHostKeyChecking", "no");
            jschSession.setConfig("PreferredAuthentications", "password");

            // authenticate using private key
//            jschSession.setPassword("Pas4Admin");
            jschSession.setPassword("Oracle78");
            //addIdentity("/home/mkyong/.ssh/id_rsa");

            // 10 seconds timeout session
            jschSession.connect(SESSION_TIMEOUT);

            var channelExec = (ChannelExec) jschSession.openChannel("exec");

            // Run a command
            channelExec.setCommand(cmd);

            // display errors to System.err
            channelExec.setErrStream(System.err);

            InputStream in = channelExec.getInputStream();

            // 5 seconds timeout channel
            channelExec.connect(CHANNEL_TIMEOUT);

            // read the result from remote server
            byte[] tmp = new byte[1024];

            while (true) {
                while (in.available() > 0) {
                    int i = in.read(tmp, 0, 1024);
                    if (i < 0) break;
                    var portion = new String(tmp, 0, i);
                    b.append(portion);
//                    System.out.print(portion);

                }
                if (channelExec.isClosed()) {
                    if (in.available() > 0) continue;
//                    System.out.println("exit-status: " + channelExec.getExitStatus());
                    break;
                }
                try {
                    Thread.sleep(100);
                } catch (Exception ee) {
                }
            }

            channelExec.disconnect();

        } catch (JSchException | IOException e) {

            e.printStackTrace();

        } finally {
            if (jschSession != null) {
                jschSession.disconnect();
            }
        }
        return b.toString();

    }

}