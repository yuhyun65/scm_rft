package kr.co.computermate.scmrft.report.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ReportJobCreateRequest(
    @NotBlank(message = "reportType is required")
    @Size(max = 50, message = "reportType length must be <= 50")
    String reportType,
    @Size(max = 50, message = "requestedByMemberId length must be <= 50")
    String requestedByMemberId
) {}
