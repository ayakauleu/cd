 package sc.dev.cd.db;

 import lombok.AllArgsConstructor;
 import lombok.NoArgsConstructor;

 import javax.persistence.*;
 import java.time.LocalDateTime;

 @Entity
 @Table(schema = "release", name = "release_history")
 @AllArgsConstructor
 @NoArgsConstructor
 public class ReleaseHistory {
     @Id
     public Long historyId;
     public Long releaseId;
     public LocalDateTime date;
     @ManyToOne
     @JoinColumn(name="state_id")
     public ReleaseState state;
     public String io;
     public String err;
 }


