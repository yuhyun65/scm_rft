package kr.co.computermate.scmrft.orderlot.api;

import java.math.BigDecimal;

public record LotDetailResponse(
    String lotId,
    String orderId,
    BigDecimal quantity,
    String status
) {
}
