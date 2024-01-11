package sc.dev.cd.db;

import org.springframework.data.jpa.repository.JpaRepository;
import sc.dev.cd.db.Project;

public interface ProjectRepository extends JpaRepository<Project, Long> {
}
