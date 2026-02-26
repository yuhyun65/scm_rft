package kr.co.computermate.scmrft.orderlot.service;

import java.util.Map;
import java.util.Set;
import org.springframework.stereotype.Component;

@Component
public class OrderStatusTransitionPolicy {
  private static final Map<String, Set<String>> ALLOWED_TRANSITIONS = Map.of(
      "PENDING", Set.of("CONFIRMED", "CANCELED"),
      "CONFIRMED", Set.of("IN_PROGRESS", "CANCELED"),
      "IN_PROGRESS", Set.of("COMPLETED", "CANCELED"),
      "COMPLETED", Set.of(),
      "CANCELED", Set.of()
  );

  public void assertAllowed(String currentStatus, String targetStatus) {
    if (currentStatus == null || targetStatus == null) {
      throw OrderLotApiException.badRequest("currentStatus and targetStatus are required.");
    }

    if (currentStatus.equals(targetStatus)) {
      throw OrderLotApiException.conflict("targetStatus is same as current status.");
    }

    Set<String> allowed = ALLOWED_TRANSITIONS.get(currentStatus);
    if (allowed == null || !allowed.contains(targetStatus)) {
      throw OrderLotApiException.conflict("status transition is not allowed.");
    }
  }
}
