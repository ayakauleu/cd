package sc.dev.cd.auth;

import org.springframework.data.repository.CrudRepository;

public interface UserRepository extends CrudRepository<User, Long> {
    User findByLoginIgnoreCase(String login);
}
