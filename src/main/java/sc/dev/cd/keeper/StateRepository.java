package sc.dev.cd.keeper;

import org.springframework.data.jpa.repository.JpaRepository;
import sc.dev.cd.model.ReleaseState;

public interface StateRepository extends JpaRepository<ReleaseState, Integer> { };
