package kr.co.computermate.scmrft.inventory.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

public record InventoryAdjustmentRequest(
    @NotBlank(message = "itemCode is required.")
    @Size(max = 100, message = "itemCode must be less than or equal to 100 characters.")
    String itemCode,
    @NotBlank(message = "warehouseCode is required.")
    @Size(max = 50, message = "warehouseCode must be less than or equal to 50 characters.")
    String warehouseCode,
    @NotNull(message = "quantityDelta is required.")
    BigDecimal quantityDelta,
    @Size(max = 100, message = "referenceNo must be less than or equal to 100 characters.")
    String referenceNo
) {
}
