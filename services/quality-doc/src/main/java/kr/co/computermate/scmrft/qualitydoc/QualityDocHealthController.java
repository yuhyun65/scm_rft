package kr.co.computermate.scmrft.qualitydoc;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/quality-doc/internal")
public class QualityDocHealthController {
  @GetMapping("/health")
  public Map<String, String> health() {
    return Map.of("service", "quality-doc", "status", "ok");
  }
}
