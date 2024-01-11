package sc.dev.cd.algo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import sc.dev.cd.crud.CrudService;
import sc.dev.cd.crud.WhereModel;

import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.SQLException;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/help")
public class Competition {
    private int[] works;

    @GetMapping("/withcomment")
    public void withcomment() throws SQLException, IOException {
        String st = Files
                .lines(Path.of("c://work//b.sql"), Charset.forName("Windows-1251"))
                .filter(it -> it.startsWith("comment on col"))
                .filter(l -> {
                    try {
                        return Files.lines(Path.of("c://work//tf.sql"))
                                .anyMatch(table -> l.contains(table));
                    } catch (IOException e) {
                        throw new RuntimeException(e);
                    }
                })
                .collect(Collectors.joining(";\n"));
        System.out.println(st);
    }

    @GetMapping("/withcomments")
    public void withcomments() throws SQLException, IOException {
        String st = Files
                .lines(Path.of("c://work//b.sql"), Charset.forName("Windows-1251"))
                .filter(it -> it.startsWith("comment "))
                .collect(Collectors.joining(";\n"));
        System.out.println(st);
    }
}

