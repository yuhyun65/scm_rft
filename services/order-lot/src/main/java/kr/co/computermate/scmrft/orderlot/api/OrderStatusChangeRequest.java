package kr.co.computermate.scmrft.orderlot.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record OrderStatusChangeRequest(
    @NotBlank(message = "targetStatus is required.")
    String targetStatus,
    @NotBlank(message = "changedBy is required.")
    @Size(max = 40, message = "changedBy must be less than or equal to 40 characters.")
    String changedBy,
    @Size(max = 200, message = "reason must be less than or equal to 200 characters.")
    String reason
) {
}
