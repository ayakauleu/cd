package sc.dev.cd.lc;

import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.util.List;

@Entity
@Table(schema = "release", name = "project_entity")
@AllArgsConstructor
@NoArgsConstructor
public class Ent {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long entityId;
    public Integer projectId;
    public String entityCaption;
    public String entityName;
    public String schema;
    public boolean isDict;
    public boolean audit;
    public boolean crud;
    public String pk;
}