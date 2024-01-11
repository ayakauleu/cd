package sc.dev.cd.db;

import org.springframework.data.jpa.repository.JpaRepository;
import sc.dev.cd.db.Migration;

public interface MigrationRepository extends JpaRepository<Migration, Long> {
}