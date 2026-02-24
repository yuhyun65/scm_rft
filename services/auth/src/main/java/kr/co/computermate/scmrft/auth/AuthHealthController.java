package kr.co.computermate.scmrft.auth;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth/internal")
public class AuthHealthController {
  @GetMapping("/health")
  public Map<String, String> health() {
    return Map.of("service", "auth", "status", "ok");
  }
}
