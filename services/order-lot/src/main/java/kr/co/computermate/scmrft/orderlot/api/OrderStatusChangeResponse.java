package kr.co.computermate.scmrft.orderlot.api;

import java.time.Instant;

public record OrderStatusChangeResponse(
    String orderId,
    String beforeStatus,
    String afterStatus,
    Instant changedAt
) {
}
