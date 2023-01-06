package sc.dev.cd.arena;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.sql.SQLException;

@RestController
@RequestMapping("/arena/ic")
public class NsiController {

    @Autowired
    private NsiService nsiService;

    @GetMapping("/rbi/{entity}")
    public String exec(@PathVariable("entity") String ent) throws SQLException {

        return nsiService.execPostgresFunction(ent);
    }
}
