package sc.dev.cd.db;

import org.springframework.data.jpa.repository.JpaRepository;
import sc.dev.cd.db.Resource;

import java.util.List;

public interface ResourceRepository extends JpaRepository<Resource, Long> {
    List<Resource> findByProjectId(Integer projectId);
}
