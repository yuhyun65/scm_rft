package kr.co.computermate.scmrft.report.api;

import java.time.Instant;
import java.util.UUID;

public record ReportJobResponse(
    UUID jobId,
    String reportType,
    String status,
    String requestedByMemberId,
    Instant requestedAt,
    Instant completedAt,
    UUID outputFileId,
    String errorMessage
) {}
