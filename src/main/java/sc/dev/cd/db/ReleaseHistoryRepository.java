package sc.dev.cd.db;

import org.springframework.data.jpa.repository.JpaRepository;
import sc.dev.cd.db.ReleaseHistory;

import java.util.List;

public interface ReleaseHistoryRepository extends JpaRepository<ReleaseHistory, Long> {
    List<ReleaseHistory> findByReleaseIdOrderByHistoryIdDesc(Long releaseId);
}
