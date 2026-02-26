package kr.co.computermate.scmrft.orderlot.api;

import java.time.Instant;

public record OrderSummaryResponse(
    String orderId,
    String supplierId,
    String status,
    Instant orderedAt
) {
}
