package sc.dev.cd.db;

import org.springframework.data.jpa.repository.JpaRepository;
import sc.dev.cd.db.ReleaseState;

public interface StateRepository extends JpaRepository<ReleaseState, Integer> { };
