package sc.dev.cd.db;

import javax.persistence.*;

@Entity
@Table(schema = "dev_code", name = "script")
public class Script {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long scriptId;
    public String scriptName;
    public Integer script_type_id;
    public String scriptBody;
}