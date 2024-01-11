package sc.dev.cd.db;
import org.springframework.data.jpa.repository.JpaRepository;
import sc.dev.cd.db.ResourceType;

public interface ResourceTypeRepository extends JpaRepository<ResourceType, Integer> {};