package sc.dev.cd.tools;

import org.springframework.stereotype.Service;
import sc.dev.cd.model.CliResponse;

import java.io.IOException;

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
}