package sc.dev.cd.model;

import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

import javax.persistence.*;

@Entity
@Table(schema = "release", name = "release_state")
@AllArgsConstructor
@NoArgsConstructor
public class ReleaseState {
    @Id
    public Integer stateId;
    public String stateName;
}