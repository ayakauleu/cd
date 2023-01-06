package sc.dev.cd.keeper;

import org.springframework.data.jpa.repository.JpaRepository;
import sc.dev.cd.model.ReleaseHistory;

import java.util.List;

public interface ReleaseHistoryRepository extends JpaRepository<ReleaseHistory, Long> {
    List<ReleaseHistory> findByReleaseIdOrderByHistoryIdDesc(Long releaseId);
}
