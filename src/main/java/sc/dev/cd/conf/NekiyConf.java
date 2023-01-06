package sc.dev.cd.conf;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class NekiyConf {
    @Bean
    public NekiiClass nekiiClass() {
        return new NekiiClass();
    }
}