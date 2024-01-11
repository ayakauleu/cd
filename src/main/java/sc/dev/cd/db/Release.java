package sc.dev.cd.db;

import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(schema = "release", name = "release")
@AllArgsConstructor
@NoArgsConstructor
public class Release {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long releaseId;
    public Long projectId;
    public LocalDateTime dateExecute;
    public String releaseName;
    @ManyToOne
    @JoinColumn(name="state_id")
    public ReleaseState state;
    public String body;
    public String undo;
    public String io;
    public String err;
}
