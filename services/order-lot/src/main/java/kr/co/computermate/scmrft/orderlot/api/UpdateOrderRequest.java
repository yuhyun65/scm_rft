package kr.co.computermate.scmrft.orderlot.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateOrderRequest(
    @NotBlank(message = "supplierId is required.")
    @Size(max = 50, message = "supplierId must be less than or equal to 50 characters.")
    String supplierId,
    @NotBlank(message = "orderDate is required.")
    String orderDate
) {
}
