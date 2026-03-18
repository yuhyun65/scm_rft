package kr.co.computermate.scmrft.orderlot.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

public record AddLotRequest(
    @NotBlank(message = "lotId is required.")
    @Size(max = 50, message = "lotId must be less than or equal to 50 characters.")
    String lotId,
    @NotNull(message = "quantity is required.")
    BigDecimal quantity,
    @Size(max = 20, message = "status must be less than or equal to 20 characters.")
    String status
) {
}
