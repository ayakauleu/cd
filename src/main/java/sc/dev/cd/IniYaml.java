package sc.dev.cd;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.PropertySource;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Component
@PropertySource("ini.yaml")
@ConfigurationProperties("app")
public class IniYaml {
    @Value("${sites}")
    public List<String> sites = new ArrayList<>();
    @Value("${bill}")
    public String bill;
}