package kr.co.computermate.scmrft.inventory;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/inventory/internal")
public class InventoryHealthController {
  @GetMapping("/health")
  public Map<String, String> health() {
    return Map.of("service", "inventory", "status", "ok");
  }
}
