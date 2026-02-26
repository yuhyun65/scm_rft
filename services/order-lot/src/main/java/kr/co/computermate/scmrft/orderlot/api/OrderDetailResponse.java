package kr.co.computermate.scmrft.orderlot.api;

import java.time.Instant;

public record OrderDetailResponse(
    String orderId,
    String supplierId,
    String status,
    Instant orderedAt,
    Instant expectedDeliveryAt,
    Integer totalLotCount
) {
}
