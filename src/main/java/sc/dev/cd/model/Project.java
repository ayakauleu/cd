package sc.dev.cd.model;

import javax.persistence.*;

@Entity
@Table(schema = "release", name = "project ")
public class Project {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long projectId;
    public String projectName;
    public Boolean wipeComments;
    public Integer databaseTypeId;
}
