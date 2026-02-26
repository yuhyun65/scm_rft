package kr.co.computermate.scmrft.orderlot.repository;

import java.time.Instant;

public record OrderEntity(
    String orderId,
    String supplierId,
    String status,
    Instant orderedAt
) {
}
