package kr.co.computermate.scmrft.file;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/file/internal")
public class FileHealthController {
  @GetMapping("/health")
  public Map<String, String> health() {
    return Map.of("service", "file", "status", "ok");
  }
}
