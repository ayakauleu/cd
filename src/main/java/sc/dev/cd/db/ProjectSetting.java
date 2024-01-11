package sc.dev.cd.db;

import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

import javax.persistence.*;

@Entity
@Table(schema = "release", name = "project_setting")
@AllArgsConstructor
@NoArgsConstructor
public class ProjectSetting {
    @Id
    public Long projectId;
    public Boolean wipeComments;
    public String keeperFilter;
}