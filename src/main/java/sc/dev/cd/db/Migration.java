package sc.dev.cd.db;

import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(schema = "release", name = "migration")
@AllArgsConstructor
@NoArgsConstructor
public class Migration {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long migrationId;
    public Long projectId;
    public LocalDateTime dateCreate;
    public String migrationName;
//    @ManyToOne
//    @JoinColumn(name="state_id")
    public Integer migrationStateId;
    public String migrationScript;
}