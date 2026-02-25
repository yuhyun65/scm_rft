package kr.co.computermate.scmrft.inventory.repository;

import java.math.BigDecimal;
import java.time.Instant;

public record InventoryBalanceEntity(
    String itemCode,
    String warehouseCode,
    BigDecimal quantity,
    Instant updatedAt
) {}
