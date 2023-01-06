package sc.dev.cd.conf;

import javax.persistence.Tuple;
import java.util.List;

public class NekiiClass {
    private int id = 5;
    private String name = "Andrei";
    public String show() {
        return String.format("Возвращаем %s и %d", name, id);
    }
}
