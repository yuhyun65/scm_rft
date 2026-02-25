package kr.co.computermate.scmrft.inventory.api;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record InventoryMovementResponse(
    UUID movementId,
    String itemCode,
    String warehouseCode,
    String movementType,
    BigDecimal quantity,
    String referenceNo,
    Instant movedAt
) {}
