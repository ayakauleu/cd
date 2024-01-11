package sc.dev.cd.auth;

import javax.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(schema = "auth", name = "user_")
public class User {
    @Id
    public Long userId;
    public String name;
    public String login;
    public String password;
    //public String roles;
}
