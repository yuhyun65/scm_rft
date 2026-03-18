package kr.co.computermate.scmrft.inventory.api;

import java.math.BigDecimal;
import java.time.Instant;

public record InventoryAdjustmentResponse(
    String movementId,
    String itemCode,
    String warehouseCode,
    BigDecimal quantityDelta,
    BigDecimal resultingQuantity,
    String referenceNo,
    Instant adjustedAt
) {
}
