package kr.co.computermate.scmrft.report;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/report/internal")
public class ReportHealthController {
  @GetMapping("/health")
  public Map<String, String> health() {
    return Map.of("service", "report", "status", "ok");
  }
}
