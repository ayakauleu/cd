package sc.dev.cd.keeper;

import org.springframework.data.jpa.repository.JpaRepository;
import sc.dev.cd.model.Project;

public interface ProjectRepository extends JpaRepository<Project, Long> {
}
