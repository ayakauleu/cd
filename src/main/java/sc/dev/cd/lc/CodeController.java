package sc.dev.cd.lc;


import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import sc.dev.cd.crud.WhereModel;

import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/code")
public class CodeController {
    @Autowired
    private CodeService codeService;

    @PostMapping("/{sid}/exec")
    public String exec(@RequestBody String params, @PathVariable Long sid) throws JsonProcessingException {
        Map<String, String> pars = new ObjectMapper().readValue(params, HashMap.class);
        return codeService.exec("", pars);
    }

    @GetMapping("/selectarray/{pid}/{eid}")
    public String selectArray(@PathVariable Long pid, @PathVariable Integer eid) throws SQLException {
        return "crudService.selectArray(pid, eid )";
    }
}
