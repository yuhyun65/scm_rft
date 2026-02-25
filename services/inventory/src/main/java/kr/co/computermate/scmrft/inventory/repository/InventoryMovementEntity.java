package kr.co.computermate.scmrft.inventory.repository;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record InventoryMovementEntity(
    UUID movementId,
    String itemCode,
    String warehouseCode,
    String movementType,
    BigDecimal quantity,
    String referenceNo,
    Instant movedAt
) {}
