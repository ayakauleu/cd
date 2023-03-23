package sc.dev.cd.lc;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface EntRepository extends JpaRepository<Ent, Long> {
//    @Query(value = "select release.log('123');", nativeQuery = true)
//    void log();

    @Query(value = "select body from release.release where release_id = :id",
            nativeQuery = true)
    String downloadReleaseBody(@Param("id") long id);

    @Procedure(procedureName = "release.release_prepare")
    Long releasePrepare(Integer pProjectId, Integer pCustomerId, String pReleaseName);

    @Procedure(procedureName = "release.sql_add")
    Long sqlAdd(Integer userId, String sqlText, Long taskId);

//    @Procedure(procedureName = "audit.enable_tracking")
//    void enableTracking(String pTable);

    List<Ent> findByProjectIdOrderByEntityName(Integer project_id);
}