package sc.dev.cd.keeper;

import org.springframework.data.jpa.repository.JpaRepository;
import sc.dev.cd.model.ProjectSetting;

import java.util.List;

public interface ProjectSettingRepository extends JpaRepository<ProjectSetting, Long> {
}