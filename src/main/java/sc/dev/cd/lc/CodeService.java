package sc.dev.cd.lc;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import sc.dev.cd.tools.StringService;

import java.util.Map;

@Service
public class CodeService implements CodeServiceInt{
    @Autowired
    private StringService stringService;
    @Override
    public String exec(String body, Map<String, String> params) {
        return stringService.templatePopulate(body, params);
    }
}
