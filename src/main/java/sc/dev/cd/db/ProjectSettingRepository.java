package sc.dev.cd.db;

import org.springframework.data.jpa.repository.JpaRepository;
import sc.dev.cd.db.ProjectSetting;

public interface ProjectSettingRepository extends JpaRepository<ProjectSetting, Long> {
}