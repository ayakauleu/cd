package sc.dev.cd.auth;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import sc.dev.cd.db.LoginDto;

@RestController
@RequestMapping("/api")
public class AuthController {
    @Autowired
    private UserRepository userRepository;
    @PostMapping("/login")
    public ResponseEntity<User> login(@RequestBody LoginDto dto) {
        var user = userRepository.findByLoginIgnoreCase(dto.user);
        if (user == null) return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        if (!dto.pass.equalsIgnoreCase(user.password)) return new ResponseEntity<>(HttpStatus.EXPECTATION_FAILED);
        user.password = null;
        return new ResponseEntity<>(user, HttpStatus.OK);
    }
}