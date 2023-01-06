package sc.dev.cd.keeper;
import org.springframework.data.jpa.repository.JpaRepository;
import sc.dev.cd.model.ResourceType;

public interface ResourceTypeRepository extends JpaRepository<ResourceType, Integer> {};