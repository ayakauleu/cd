package sc.dev.cd.keeper;

import org.springframework.data.jpa.repository.JpaRepository;
import sc.dev.cd.model.Resource;

import java.util.List;

public interface ResourceRepository extends JpaRepository<Resource, Long> {
    List<Resource> findByProjectId(Integer projectId);
}
