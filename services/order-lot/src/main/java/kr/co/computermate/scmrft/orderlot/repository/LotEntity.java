package kr.co.computermate.scmrft.orderlot.repository;

import java.math.BigDecimal;

public record LotEntity(
    String lotId,
    String orderId,
    BigDecimal quantity,
    String status
) {
}
