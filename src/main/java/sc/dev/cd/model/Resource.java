package sc.dev.cd.model;

import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

import javax.persistence.*;

@Entity
@Table(schema = "release", name = "project_resource")
@AllArgsConstructor
@NoArgsConstructor
public class Resource {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long resourceId;
    public Integer projectId;
    @Column(name = "type_id")
    public Integer typeId;
    @ManyToOne
    @JoinColumn(name="type_id", insertable=false, updatable=false)
    public ResourceType type;
    public String address;
    public String login;
    public String password;
}
