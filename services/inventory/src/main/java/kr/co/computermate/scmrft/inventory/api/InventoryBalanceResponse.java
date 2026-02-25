package kr.co.computermate.scmrft.inventory.api;

import java.math.BigDecimal;
import java.time.Instant;

public record InventoryBalanceResponse(
    String itemCode,
    String warehouseCode,
    BigDecimal quantity,
    Instant updatedAt
) {}
