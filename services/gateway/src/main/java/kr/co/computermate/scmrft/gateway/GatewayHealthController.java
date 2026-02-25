package kr.co.computermate.scmrft.gateway;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/gateway/internal")
public class GatewayHealthController {
  @GetMapping("/health")
  public Map<String, String> health() {
    return Map.of("service", "gateway", "status", "ok");
  }
}
