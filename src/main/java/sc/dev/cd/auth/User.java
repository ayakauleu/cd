package sc.dev.cd.auth;

import javax.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(schema = "kp_core", name = "user_")
public class User {
    @Id
    public BigDecimal userId;
    public String name;
    public String login;
    public String password;
    //public String roles;
}
