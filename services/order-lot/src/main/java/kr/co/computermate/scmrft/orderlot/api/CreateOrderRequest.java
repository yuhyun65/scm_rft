package kr.co.computermate.scmrft.orderlot.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateOrderRequest(
    @NotBlank(message = "orderId is required.")
    @Size(max = 50, message = "orderId must be less than or equal to 50 characters.")
    String orderId,
    @NotBlank(message = "supplierId is required.")
    @Size(max = 50, message = "supplierId must be less than or equal to 50 characters.")
    String supplierId,
    @NotBlank(message = "orderDate is required.")
    String orderDate,
    @Size(max = 20, message = "status must be less than or equal to 20 characters.")
    String status
) {
}
