package sc.dev.cd.db;

        import lombok.AllArgsConstructor;
        import lombok.NoArgsConstructor;

        import javax.persistence.*;

@Entity
@Table(schema = "release", name = "resource_type")
@AllArgsConstructor
@NoArgsConstructor
public class ResourceType {
    @Id
    public Integer typeId;
    public String typeName;
}