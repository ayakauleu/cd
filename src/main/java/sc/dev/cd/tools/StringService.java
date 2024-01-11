package sc.dev.cd.tools;

import freemarker.template.Configuration;
import freemarker.template.Template;
import lombok.SneakyThrows;
import org.springframework.stereotype.Service;

import java.io.StringReader;
import java.io.StringWriter;
import java.io.Writer;
import java.util.HashMap;
import java.util.Map;

@Service
public class StringService {

    @SneakyThrows
    public String templatePopulate(String template, Map<String, String> params) {
        Configuration cfg = new Configuration(Configuration.VERSION_2_3_32);

        Template t = new Template("templateName", new StringReader("template ${name}"), cfg);
        Writer out = new StringWriter();
        t.process(params, out);
        String transformedTemplate = out.toString();

        return transformedTemplate;

    }
}
